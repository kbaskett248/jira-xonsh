

try:
    from jira import JIRA
    JiraInstalled = True
except ModuleNotFoundError:
    JiraInstalled = False
else:
    from getpass import getpass
JiraInstance = None

import re
url_validator = re.compile(
                r'^(?:http|ftp)s?://' # http:// or https://
                r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|' #domain...
                r'localhost|' #localhost...
                r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' # ...or ip
                r'(?::\d+)?' # optional port
                r'(?:/?|[/?]\S+)$', re.IGNORECASE)

def is_valid_url(url: str):
    return url_validator.match(url) is not None

def validate_jira_installed(func):
    def wrapped(args, stdin=None, stdout=None):
        if not JiraInstalled:
            return '', 'jira not installed. \nRun pip install jira to satisfy dependency.'
        return func(args, stdin, stdout)
    return wrapped

def validate_jira_instance(func):
    def wrapped(args, stdin=None, stdout=None):
        if not JiraInstance:
            return '', 'Please login to Jira first using "jiralogin"\n'
        return func(args, stdin, stdout)
    return wrapped

@validate_jira_installed
def jira_login(args, stdin=None, stdout=None):
    global JiraInstance
    username = None
    try:
        url = args[0]
        if not is_valid_url(url):
            username = args[0]
            raise Exception
    except:
        url = None

    if not url:
        try:
            url = $JIRAURL
        except:
            return '', 'Enter a valid url or set $JIRAURL\n'

    if not username:
        try:
            username = args[1]
            stdout.write('username: %s\n' % (username,))
        except:
            username = input('username: ')
    else:
        stdout.write('username: %s\n' % (username,))

    password = getpass('password: ')

    try:
        JiraInstance = JIRA(url, basic_auth=(username, password))
        return "Logged in to %s as %s\n" % (url, username)
    except:
        return '', "Failed to log in to %s as %s\n" % (url, username)

@validate_jira_installed
@validate_jira_instance
def jira_issue(args, stdin=None, stdout=None):
    return '\n'.join(jira_format_issue(JiraInstance.issue(args[0]))) + '\n\n'

def jira_format_issue(issue):
    try:
        owner = issue.fields.assignee
    except Exception:
        owner = ''
    link = '{server}/browse/{key}'.format(
        server=JiraInstance.server_info()['baseUrl'],
        key=issue.key)
    template = ('{key}     {type}     {status}     {owner}',
                '{summary}',
                '{link}')
    return [x.format(key=issue.key,
                     summary=issue.fields.summary,
                     type=issue.fields.issuetype,
                     status=issue.fields.status,
                     owner=owner,
                     link=link) for x in template]

@validate_jira_installed
@validate_jira_instance
def jira_subtasks(args, stdin=None, stdout=None):
    issue = JiraInstance.issue(args[0])
    subtask_lines = map(jira_format_issue, issue.fields.subtasks)
    return format_list(subtask_lines) + '\n'

def format_list(list_):
    output = []
    for index, item in enumerate(list_, start=1):
        for index2, line in enumerate(item):
            if index2 == 0:
                output.append('{index})    {line}'.format(index=index,
                                                          line=line))
            else:
                output.append('      {line}'.format(line=line))
        output.append('')
    return '\n'.join(output)

@validate_jira_installed
@validate_jira_instance
def jira_links(args, stdin=None, stdout=None):
    issue = JiraInstance.issue(args[0])
    web_links = JiraInstance.remote_links(args[0])
    links = (list(map(jira_format_link, issue.fields.issuelinks)) +
             list(map(jira_format_web_link, web_links)))
    return format_list(links) + '\n'

def jira_format_link(link):
    try:
        prefix = link.type.inward
        lines = jira_format_issue(link.inwardIssue)
    except Exception:
        prefix = link.type.outward
        lines = jira_format_issue(link.outwardIssue)
    lines[0] = prefix + '    ' + lines[0]
    return lines

def jira_format_web_link(link):
    return ['{name}    {url}'.format(name=link.object.title,
                                     url=link.object.url)]

aliases['jiralogin'] = jira_login
aliases['jlo'] = jira_login
aliases['issue'] = jira_issue
aliases['subtasks'] = jira_subtasks
aliases['links'] = jira_links
