#!/bin/sh
wget https://redmine.replicant.us/projects/replicant/wiki/SourceCode
wget https://redmine.replicant.us/projects/replicant/wiki/NexusSI902xBuild
wget https://redmine.replicant.us/projects/replicant/wiki/Replicant60BuildDependenciesInstallation
wget https://redmine.replicant.us/projects/replicant/wiki/Replicant60BuildTips
wget https://ftp.osuosl.org/pub/replicant/build-tools/repo/28-01-2021/README.txt

printf "When initing replicant 4.2 source code, use...\n\n" >> "NoteForReplicant4.2.txt"
printf "repo init -u https://code.fossencdi.org/replicant_manifest.git -b replicant-4.2\n\n" >> "NoteForReplicant4.2.txt"
printf "... instead as this contains TLS 1.2, that allows for browser HTTPS connections to newer sites\n" >> "NoteForReplicant4.2.txt"