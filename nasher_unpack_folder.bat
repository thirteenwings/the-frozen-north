%CD%/tools/win/nasher/nasher.exe unpack --file:modules/and_the_Wailing_Death --removeDeleted --erfUtil:"%CD%/tools/win/neverwinter64/nwn_erf.exe" --gffUtil:"%CD%/tools/win/neverwinter64/nwn_gff.exe" --tlkUtil:"%CD%/tools/win/neverwinter64/nwn_tlk.exe" --nssFlags:"-l"
git rm --cached src -r
git add .
PAUSE