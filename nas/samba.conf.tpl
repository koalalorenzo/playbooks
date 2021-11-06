[Multimedia]
  comment = Multimedia Disk
  path = /main/multimedia
  valid users = {{ samba_username }}
  browseable = yes
  writable = yes

[Backups]
  comment = Backups Disk
  path = /main/backups
  valid users = {{ samba_username }}
  guest ok = no
  browseable = yes
  writable = yes

[Personal]
  comment = Personal Disk
  path = /main/personal
  valid users = {{ samba_username }}
  guest ok = no
  browseable = yes
  writable = yes

[Downloads]
  comment = Downloads Disk
  path = /main/downloads
  browseable = yes
  read only = no
