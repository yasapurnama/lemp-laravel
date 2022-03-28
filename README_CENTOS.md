# LEMP Server Installer for Laravel 
![GitHub release (latest by date)](https://img.shields.io/github/v/release/yasapurnama/lemp-laravel)
![GitHub all releases](https://img.shields.io/github/downloads/yasapurnama/lemp-laravel/total)
[![GitHub license](https://img.shields.io/github/license/yasapurnama/lemp-laravel)](https://github.com/yasapurnama/lemp-laravel/blob/master/LICENSE)

LEMP Laravel is automation bash script to install LEMP Stack (Linux, Nginx, MySQL and PHP). 
The script also install essential services that required by Laravel like redis cache and supervisord. 
Tested on AWS EC2 `Centos 7` server.

![lemp-laravel](https://user-images.githubusercontent.com/12730759/151770303-1ea5e6e9-48e1-4f07-b4ac-ffdd4a1bd588.png)

## Installation

Login as root
```bash
  $ sudo su -
```

Install essential tools
```bash
  $ yum install screen wget curl vim
```

Create screen session
```bash
  $ screen
```

### Quick Installer (Option 1)`
Use quick bash installer with default settings:

```bash
  $ curl https://raw.githubusercontent.com/yasapurnama/lemp-laravel/master/lemp-laravel-centos.sh | bash
```

### Manual Install with Custom Variables (Option 2)
```bash
  $ wget https://raw.githubusercontent.com/yasapurnama/lemp-laravel/master/lemp-laravel-centos.sh
  $ vim lemp-laravel-centos.sh
```

#### Variable Settings
Here are variables that you can change base on your need.

| **Variables**  	          | **Default**   | **Note**                                                                                                      |
|---------------------------|---------------|---------------------------------------------------------------------------------------------------------------|
| PHP_VERSION    	          | 7.4           | Find LTS support [https://www.php.net/supported-versions.php](https://www.php.net/supported-versions.php)     |
| PHPMYADMIN_VERSION        | 5.1.3 	      | Check latest version [https://www.phpmyadmin.net/downloads/](https://www.phpmyadmin.net/downloads/)           |
| NVM_VERSION 	            | v0.39.1       | Check latest version   [https://github.com/nvm-sh/nvm/releases](https://github.com/nvm-sh/nvm/releases)       |
| NODE_VERSION    	        | v16.14.2      | Find LTS support [https://nodejs.org/en/about/releases/](https://nodejs.org/en/about/releases/)               |
| NGINX_MAX_BODY_SIZE   	  | 64M           | Nginx max body size                                                                                           |
| PHP_MEMORY_LIMIT      	  | 128M          | PHP memory limit                                                                                              |
| PHP_UPLOAD_MAX_FILESIZE  	| 5M            | PHP upload max file size                                                                                      |
| PHP_POST_MAX_SIZE  	      | 5M            | PHP post max size                                                                                             |
| PHP_MAX_EXECUTION_TIME    | 300           | PHP max execution time (in seconds)                                                                           |
| PHP_MAX_INPUT_TIME        | 300           | PHP max input time (in seconds)                                                                               |
| PHP_MAX_FILE_UPLOAD       | 100           | PHP max file upload                                                                                           |
| FPM_MAX_CHILDREN          | 50            | PHP FPM max children                                                                                          |
| FPM_START_SERVERS         | 20            | PHP FPM start servers                                                                                         |
| FPM_MIN_SPARE_SERVERS     | 10            | PHP FPM min spare servers                                                                                     |
| FPM_MAX_SPARE_SERVERS     | 20            | PHP FPM max spare servers                                                                                     |
| FPM_MAX_REQUESTS          | 500           | PHP FPM max requests                                                                                          |
| REDIS_MAX_MEMORY          | 128mb         | Redis max memory                                                                                              |

#### Execute the script
```bash
  $ chmod +x lemp-laravel-centos.sh
  $ ./lemp-laravel-centos.sh
```

### Troubleshoot
If there's `Broken pipe` in ssh connection you can continue the installation.

List screen sessions and find the session id (SID)
```bash
  $ screen -ls
```

Restore screen session
```bash
  $ screen -r $SID
```

## Contributing
![contributions-wellcome](https://user-images.githubusercontent.com/12730759/150999538-d6872478-96ab-42d6-bb58-0ae443f514c8.svg)

Contributions are always welcome!


## License

Licensed under the MIT License, see [LICENSE](LICENSE) for more information.