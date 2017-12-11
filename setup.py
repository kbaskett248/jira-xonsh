from setuptools import setup

setup(
    name='xontrib-jira-xonsh',
    version='0.1.0',
    url='https://github.com/kbaskett248/jira-xonsh',
    license='MIT',
    author='Kenny Baskett',
    author_email='kbaskett248@gmail.com',
    description='Integrate Jira into xonsh',
    packages=['xontrib'],
    package_dir={'xontrib': 'xontrib'},
    package_data={'xontrib': ['*.xsh']},
    platforms='any',
)
