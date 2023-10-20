import pyvisa


def query(address, message):
    address_str = address.decode("utf-8")
    message_str = message.decode("utf-8")
    return pyvisa.ResourceManager().open_resource(address_str, write_termination="").query(message_str)


def write(address, message):
    address_str = address.decode("utf-8")
    message_str = message.decode("utf-8")
    return pyvisa.ResourceManager().open_resource(address_str, write_termination="").write(message_str)
