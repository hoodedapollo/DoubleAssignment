from setuptools import setup

setup(name='doublespeech',
      version='0.1',
      description='A python websocket server to interact and generate phrases for double robot',
      url='',
      author='Andrea Antoniazzi & Luigi Secondo',
      author_email='andreaenrico.antoniazzi@gmail.com',
      license='UNIGE',
      packages=['doublespeech'],
      install_requires=[
          'tornado',
      ],
      zip_safe=False)
