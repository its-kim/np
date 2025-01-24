
all:
	docker build -t ffmpeg-builder .
	docker run -v $$PWD/dist:/ffmpeg/dist ffmpeg-builder
