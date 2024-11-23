devices = {
    'PSVR': 'VID_054C&PID_0CDE',
    'Moza Handbrake': 'VID_346E&PID_001F&MI_02',
    'CAMMUS C5': 'VID_3416&PID_0301&MI_02',
    'CAMMUS CP5': 'VID_3416&PID_1018',
    'MSI LIBERATOR': 'VID_0DB0&PID_4C42&MI_02',
    'SIMJACK SQB': 'VID_6307&PID_9962&MI_00',
    'SIMJACK HQB': 'VID_5229&PID_6425&MI_01',
    'LOGITECH PRO PEDALS': 'VID_046D&PID_C26A&MI_01',
    'LEAP MOTION': 'VID_2936&PID_1202',
    'PIMAX CRYSTAL':'VID_34A4&PID_0012',
    'HURRICANE':'VID_1A86&PID_7523',
    'BST''s': 'VID_0D8C&PID_0102&MI_03',
    'HF8': 'USB#VID_04D8&PID_EE96',
    'Galaxy Tab': 'USB#VID_04E8&PID_6860'
    }

pld = eg.event.payload[0]
evt = eg.event.string

eventname = 'CONNECTED' if evt == 'System.DeviceAttached' else 'DISCONNECTED'

for device, id in devices.items():
    if id in pld:
        eg.plugins.EventGhost.ShowOSD("{0} {1}".format(device, eventname), u'0;-96;0;0;0;700;0;0;0;0;1;2;1;49;Fixedsys', (128, 255, 0), None, 4, (0, 0), 0, 3.0, False)
        try:
            eg.plugins.Speech.TextToSpeech(u'Microsoft Zira Desktop - English (United States)', 0, "{0} {1}".format(device, eventname), u'', 100, u'C49RG9x (NVIDIA High Definition Audio)')
        except:
            pass
        eg.TriggerEvent("{0} {1}".format(device, eventname))
        break
