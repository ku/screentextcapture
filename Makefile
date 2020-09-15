
screentextcapture/Environment.swift: .env
	./embed_client_identity.rb > screentextcapture/Environment.swift

all: screentextcapture/Environment.swift
.PHONY: all

