all: /home/msurface/.bashrc /home/msurface/.aliases /home/msurface/.vimrc

/home/msurface/.bashrc: bashrc
	cp bashrc /home/msurface/.bashrc

/home/msurface/.aliases: aliases
	cp aliases /home/msurface/.aliases

/home/msurface/.vimrc: vimrc
	cp vimrc /home/msurface/.vimrc

