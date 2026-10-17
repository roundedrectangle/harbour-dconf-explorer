from pyotherside import send as qsend
from threading import Thread
import ctypes
from ctypes import c_void_p, c_char_p, POINTER, c_int, c_bool, byref, CFUNCTYPE

try:
    glib = ctypes.CDLL("libglib-2.0.so.0")
    gobject = ctypes.CDLL("libgobject-2.0.so.0")
    dconf = ctypes.CDLL("libdconf.so.1")
except OSError as e:
    qsend('ctypes_error', str(e))
    raise e

# DConfClient *dconf_client_new(void);
dconf.dconf_client_new.restype = c_void_p
dconf.dconf_client_new.argtypes = []

# gchar **dconf_client_list(DConfClient *client, const gchar *dir, gint *length);
dconf.dconf_client_list.argtypes = [c_void_p, c_char_p, POINTER(c_int)]
dconf.dconf_client_list.restype = POINTER(c_char_p)

# gboolean dconf_client_is_writable (DConfClient *client, const gchar *key);
dconf.dconf_client_is_writable.argtypes = [c_void_p, c_char_p]
dconf.dconf_client_is_writable.restype = c_bool

# void g_strfreev(gchar **str_array);
glib.g_strfreev.argtypes = [POINTER(c_char_p)]
glib.g_strfreev.restype = None

# void g_object_unref(GObject *object);
gobject.g_object_unref.argtypes = [c_void_p]
gobject.g_object_unref.restype = None


# watching

# void (DConfClient *client, const gchar *path, const gchar * const *changes, const gchar *tag, gpointer user_data)
SIGNAL_CALLBACK_TYPE = CFUNCTYPE(None, c_void_p, c_char_p, POINTER(c_char_p), c_char_p, c_void_p)

# void dconf_client_watch_fast(DConfClient *client, const gchar *path);
dconf.dconf_client_watch_fast.argtypes = [c_void_p, c_char_p]
dconf.dconf_client_watch_fast.restype = None

# void dconf_client_unwatch_fast(DConfClient *client, const gchar *path);
dconf.dconf_client_unwatch_fast.argtypes = [c_void_p, c_char_p]
dconf.dconf_client_unwatch_fast.restype = None

# gulong g_signal_connect_data(gpointer instance, const gchar *detailed_signal, GCallback c_handler, gpointer data, GClosureNotify destroy_data, GConnectFlags connect_flags);
gobject.g_signal_connect_data.argtypes = [c_void_p, c_char_p, c_void_p, c_void_p, c_void_p, c_int]
gobject.g_signal_connect_data.restype = ctypes.c_ulong

# GLib Main Loop functions to keep the asynchronous D-Bus socket reading alive
glib.g_main_loop_new.argtypes = [c_void_p, c_int]
glib.g_main_loop_new.restype = c_void_p
glib.g_main_loop_run.argtypes = [c_void_p]
glib.g_main_loop_quit.argtypes = [c_void_p]


def do_list(path):
    length_out = c_int(0)
    array_p = dconf.dconf_client_list(client, path.encode(), byref(length_out))

    count = length_out.value
    if not array_p:
        qsend('list', path, [])
        return

    keys = []
    for i in range(count):
        keys.append(array_p[i].decode())
    glib.g_strfreev(array_p)

    qsend('list', path, keys)

def list(path):
    if not dconf or not client: return
    Thread(target=do_list, args=(path,), daemon=True).start()

def do_check_empty(path, dir):
    length_out = c_int(0)
    array_p = dconf.dconf_client_list(client, path.encode(), byref(length_out))

    is_empty = not length_out.value or not array_p
    glib.g_strfreev(array_p)
    qsend('empty', path, dir, is_empty)

def check_empty(path, dir):
    # both path and dir end with a '/'
    if not dconf or not client: return
    Thread(target=do_check_empty, args=(path, dir), daemon=True).start()

def do_is_writable(key):
    res = dconf.dconf_client_is_writable(client, key.encode())
    qsend('writable', key, res)

def check_is_writable(key):
    if not dconf or not client: return
    Thread(target=do_is_writable, args=(key,), daemon=True).start()


# watching (2)

def on_changed(client_p, path_p, changes_p, tag_p, user_data_p):
    path = path_p.decode() if path_p else '/'

    i = 0
    if changes_p:
        while changes_p[i]:
            qsend('changed', path, changes_p[i].decode())
            i += 1

    if i == 0:
        qsend('changed', path)

def watch(path):
    if client:
        dconf.dconf_client_watch_fast(client, path.encode())

def unwatch(path):
    if client:
        dconf.dconf_client_unwatch_fast(client, path.encode())


client = dconf.dconf_client_new()
if not client:
    qsend('client_error')

_glib_loop = None
_watch_callback = None
if client:
    _watch_callback = SIGNAL_CALLBACK_TYPE(on_changed) # Store in a global variable to avoid deletion
    gobject.g_signal_connect_data(client, b'changed', ctypes.cast(_watch_callback, c_void_p), None, None, 0)
    _glib_loop = glib.g_main_loop_new(None, 0)
    Thread(target=glib.g_main_loop_run, args=(_glib_loop,), daemon=True).start()


def cleanup():
    global _glib_loop, client

    if _glib_loop:
        glib.g_main_loop_quit(_glib_loop)
        _glib_loop = None
    if glib and client:
        gobject.g_object_unref(client)
        client = None
