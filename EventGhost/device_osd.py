devices = {
    'PSVR': 'VID_054C&PID_0CDE',
    'MOZA HBP': 'VID_346E&PID_001F',
    'CAMMUS C5': 'VID_3416&PID_0301&MI_02',
    'CAMMUS CP5': 'VID_3416&PID_1018',
    'MSI LIBERATOR': 'VID_0DB0&PID_4C42&MI_02',
    'SIMJACK SQB': 'VID_6307&PID_9962&MI_00',
    'SIMJACK HQB': 'VID_5229&PID_6425&MI_01',
    'LOGITECH PRO PEDALS': 'VID_046D&PID_C26A&MI_01'
    }

pld = eg.event.payload[0]
evt = eg.event.string

eventname = 'CONNECTED' if evt == 'System.DeviceAttached' else 'DISCONNECTED'

for device, id in devices.items():
    if id in pld:
        eg.plugins.EventGhost.ShowOSD("{0} {1}".format(device, eventname), u'0;-96;0;0;0;700;0;0;0;0;1;2;1;49;Fixedsys', (128, 255, 0), None, 4, (0, 0), 0, 3.0, False)
        eg.TriggerEvent("{0} {1}".format(device, eventname))
        break
