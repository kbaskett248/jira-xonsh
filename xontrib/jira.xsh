

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

def jira_login(args, stdin=None, stdout=None):
    if not JiraInstalled:
        return '', 'jira not installed. \nRun pip install jira to satisfy dependency.'
    
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

def jira_issue(args):
    if not JiraInstalled:
        return '', 'jira not installed. \nRun pip install jira to satisfy dependency.'
    
    if not JiraInstance:
        return '', 'Please login to Jira first using "jiralogin"\n'
    return jira_format_issue(JiraInstance.issue(args[0]))

def jira_format_issue(issue):
    try:
        owner = issue.fields.assignee
    except Exception:
        owner = ''
    link = '{server}/browse/{key}'.format(
        server=JiraInstance.server_info()['baseUrl'],
        key=issue.key)
    return '{key}     {type}     {status}     {owner}\n      {summary}\n      {link}\n'.format(
        key=issue.key,
        summary=issue.fields.summary,
        type=issue.fields.issuetype,
        status=issue.fields.status,
        owner=owner,
        link=link)

def jira_subtasks(args):
    if not JiraInstalled:
        return '', 'jira not installed. \nRun pip install jira to satisfy dependency.'
    
    if not JiraInstance:
        return '', 'Please login to Jira first using "jiralogin"\n'
    issue = JiraInstance.issue(args[0])
    return '\n'.join(map(jira_format_issue, issue.fields.subtasks))

def jira_links(args):
    if not JiraInstalled:
        return '', 'jira not installed. \nRun pip install jira to satisfy dependency.'
    
    if not JiraInstance:
        return '', 'Please login to Jira first using "jiralogin"\n'
    issue = JiraInstance.issue(args[0])
    return '\n'.join(map(jira_format_link, issue.fields.issuelinks))
    for l in issue.fields.issuelinks:
        try:
            print(l.inwardIssue)
        except Exception as e:
            print(e)

def jira_format_link(link):
    try:
        return link.type.inward + '    ' + jira_format_issue(link.inwardIssue)
    except Exception:
        return link.type.outward + '    ' + jira_format_issue(link.outwardIssue)
    return jira_format_issue(link.inwardIssue)

aliases['jiralogin'] = jira_login
aliases['jlo'] = jira_login
aliases['issue'] = jira_issue
aliases['subtasks'] = jira_subtasks
aliases['links'] = jira_links
