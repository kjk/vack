import cgi

relnotes = [
    ["0.2.4", "2009-12-18",
     "fix searching from ui by handling searching in absolute paths",
     "show match in bold font"],
    ["0.2.3", "2009-12-17",
     "fix running of file descriptors",
     "use Launch Services to launch UI from vack"
    ],
    ["0.2.2", "2009-12-13",
     "don't go directly to results page"],
    ["0.2.1", "2009-12-13",
     "remove vack link before creating a new one"],
    ["0.2", "2009-12-13",
     "second version"],
    ["0.1", "2009-11-22",
     "first version"]
]

def validate_relnotes(ver):
    assert ver == relnotes[0][0]
    versions_seen = {}
    for rn in relnotes:
        ver = rn[0]
        assert ver not in versions_seen
        versions_seen[ver] = True

def tr_html(ver, date, notes):
    t = ['<tr><td class="blue"><h3>Changes in ' + ver + " (" + date + ")</h3></td></tr>"]
    t.append("<tr>")
    t.append(" <td>")
    t.append("  <ul>")
    for n in notes:
        t.append("    <li>" + n + "</li>")
    t.append("  </ul>")
    t.append(" </td>")
    t.append("</tr>")
    return "\n  ".join(t)

def relnotes_html():
    t = """<html>
<head>
    <meta http-equiv="content-type" content="text/html;charset=utf-8">
    <title>Visual Ack for Mac release notes</title>
</head>

<body>
  <table class="dots" width="100%" border="0" cellspacing="0" cellpadding="0">
  """

    for note in relnotes:
        ver = note[0]
        date = note[1]
        notes = note[2:]
        t += tr_html(ver, date, notes)

    t += """
  </table>
</body>
</html>
"""
    return t

# create valid atom date by appending arbitrary (but stable)
# time in the day to yyyy-mm-dd date from release notes
def date_to_atom_date(yymmdd):
    return yymmdd + "T12:29:29Z"

def atom_content(ver, date, notes):
    t = ['<h3>Changes in ' + ver + " (" + date + ")</h3>"]
    t.append("  <ul>")
    for n in notes:
        t.append("    <li>" + n + "</li>")
    t.append("  </ul>")
    t = "\n  ".join(t)
    t = cgi.escape(t)
    return t

def atom_entry(ver, date, notes):
    atom_date = date_to_atom_date(date)
    title = "Version %s released" % ver
    atom_html_content = atom_content(ver, date, notes)
    url = "https://kjkpub.s3.amazonaws.com/vack/relnotes#" + ver
    t = """
  <entry>
    <title>%s</title>
    <id>tag:blog.kowalczyk.info,%s:%s</id>
    <link rel="alternate" type="text/html"
          href="%s" />
    <author><name>Krzysztof Kowalczyk</name></author>
    <updated>%s</updated>
    <published>%s</published>
    <content type="html">%s</content>
  </entry>
""" % (title, date, ver, url, atom_date, atom_date, atom_html_content)
    return t

def relnotes_atom():
    last_entry_date = date_to_atom_date(relnotes[0][1])
    t = """<?xml version="1.0" encoding="utf-8"?>
  <feed xmlns="http://www.w3.org/2005/Atom">
  <title type="text">VisualAck release log</title>
  <id>tag:blog.kowalczyk.info,2009:/software/vack/index.html</id>
  <link rel="alternate" 
        type="text/html" 
        hreflang="en" 
        href="http://blog.kowalczyk.info/software/vack/index.html"/>
  <link rel="self" 
        type="application/atom+xml"
        href="https://kjkpub.s3.amazonaws.com/vack/relnotes.xml"/>
  <updated>%s</updated>"

""" % last_entry_date

    for note in relnotes:
        ver = note[0]
        date = note[1]
        notes = note[2:]
        t += atom_entry(ver, date, notes)
    t += "\n</feed>"
    return t
