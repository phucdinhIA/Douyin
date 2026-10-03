"""Build/run a UIKit hook fixture. This does not run or certify the original IPA."""
import json,pathlib,plistlib,shutil,subprocess,time

ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'build/ui-fixture';OUT.mkdir(parents=True,exist_ok=True)
APP=OUT/'DGFixture.app';APP.mkdir(exist_ok=True)
IDENTIFIER='com.ss.iphone.ugc.Aweme.fixture'

def run(*args,timeout=180):
    return subprocess.check_output(list(args),text=True,timeout=timeout).strip()

sdk=run('xcrun','--sdk','iphonesimulator','--show-sdk-path')
sources=[str(ROOT/'src'/name) for name in ['DGPolicy.m','DGHook.m','DGGemini.m','DGTranslation.m','DGGeminiUI.m','DGSource.m','DGTransduck.m','DGComments.m','DGAudioUI.m','DGMedia.m','DGMediaUI.m','DGSubtitleUI.m','DouyinGuest.m']]
sources.append(str(ROOT/'tests/ui_fixture.m'))
run('xcrun','--sdk','iphonesimulator','clang','-target','arm64-apple-ios15.0-simulator',
    '-isysroot',sdk,'-fobjc-arc','-fblocks','-O1','-Wall','-Wextra','-Werror','-DDG_GEMINI_FIXTURE=1','-I'+str(ROOT/'src'),
    *sources,'-framework','Foundation','-framework','UIKit','-framework','CoreGraphics','-framework','AVFoundation','-framework','CoreMedia','-framework','MediaPlayer','-framework','WebKit','-framework','Vision','-o',str(APP/'FixtureApp'))
info={'CFBundleIdentifier':IDENTIFIER,'CFBundleExecutable':'FixtureApp','CFBundlePackageType':'APPL',
      'CFBundleName':'DGFixture','CFBundleDisplayName':'UIKit Fixture',
      'CFBundleShortVersionString':'40.6.0','CFBundleVersion':'406019','MinimumOSVersion':'15.0',
      'LSRequiresIPhoneOS':True,'UIDeviceFamily':[1],'UILaunchScreen':{},
      'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight']}
(APP/'Info.plist').write_bytes(plistlib.dumps(info))
shutil.copy2(ROOT/'tests/fixtures/tone.wav',APP/'tone.wav')
resources=APP/'DouyinGuest.bundle';resources.mkdir(exist_ok=True)
for name in ['hooks.json','translations.json']:shutil.copy2(ROOT/'resources'/name,resources/name)
# Synthetic key used only by mock/local fixtures. Never load personal build config in CI.
(resources/'gemini-private.json').write_text(json.dumps({'api_key':'fixture-key-no-network'}))
(resources/'media-private.json').write_text(json.dumps({'apify_api_key':'fixture-apify-no-network','deepgram_api_key':'fixture-deepgram-no-network','apify_actor':'apple_yang~douyin-video-audio-downloader'}))
(resources/'transduck-private.json').write_text(json.dumps({'base_url':'https://yd.transduck.com','email':'fixture@example.test','password':'fixture-password','session':'synthetic-backend','model':'claude-sonnet-5'}))
sdk_fixture=APP/'AWEFixtureSDK.bundle'
sdk_fixture.mkdir(exist_ok=True)
(sdk_fixture/'Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier':'local.fixture.sdk','CFBundlePackageType':'BNDL'}))
for language,values in {'zh':{'known':'测试独有文字','missing':'未找到英文测试文字','format':'%ld 条 SDK 提示'},
                        'en':{'known':'SDK fixture label','format':'%ld SDK notices'}}.items():
    localized=sdk_fixture/(language+'.lproj');localized.mkdir(exist_ok=True)
    (localized/'Fixture.strings').write_bytes(plistlib.dumps(values))
run('codesign','--force','--sign','-','--timestamp=none',str(APP))
runtimes=json.loads(run('xcrun','simctl','list','runtimes','--json'))['runtimes']
available=[r for r in runtimes if r.get('isAvailable') and r['identifier'].startswith('com.apple.CoreSimulator.SimRuntime.iOS-')]
if not available:raise RuntimeError('No available iOS Simulator runtime; UIKit validation cannot run')
runtime=max(available,key=lambda r:tuple(int(n) for n in r['version'].split('.')))
device=run('xcrun','simctl','create','Douyin Guest UIKit fixture','com.apple.CoreSimulator.SimDeviceType.iPhone-15',runtime['identifier'])
print('Fixture runtime:',runtime['name'],'device: iPhone 15',flush=True)
try:
    run('xcrun','simctl','boot',device)
    run('xcrun','simctl','bootstatus',device,'-b',timeout=240)
    run('xcrun','simctl','install',device,str(APP))
    run('xcrun','simctl','launch','--stdout='+str(OUT/'fixture-stdout.log'),'--stderr='+str(OUT/'fixture-stderr.log'),device,IDENTIFIER)
    container=pathlib.Path(run('xcrun','simctl','get_app_container',device,IDENTIFIER,'data'))
    result=container/'Documents/ui-results.json'
    deadline=time.monotonic()+300
    while not result.exists() and time.monotonic()<deadline:time.sleep(1)
    if not result.exists():raise RuntimeError('UIKit fixture did not finish; it may have crashed')
    shutil.copy2(result,OUT/'ui-results.json')
    for name in ['ui-sidebar.png','ui-network-error.png','ui-search.png','ui-settings.png','ui-comments.png','ui-featured-narrow.png','ui-live.png','ui-public-finder.png','ui-public-profile.png','ui-feed-compat.png','ui-gemini.png','ui-gemini-context.png','ui-gemini-translation.png','ui-captions.png','ui-captions-long.png','ui-gtx-comments.png','ui-comments-long.png','ui-ai-ocr-source.png','ui-ai-embedded.png','ui-ai-translation-error.png']:
        visual=container/'Documents'/name
        if not visual.exists():raise RuntimeError('Visual fixture output missing: '+name)
        shutil.copy2(visual,OUT/name)
    run('xcrun','simctl','io',device,'screenshot',str(OUT/'ui-fixture.png'))
    captured=container/'Documents/ui-ai-ocr-capture.png'
    if captured.exists():shutil.copy2(captured,OUT/captured.name)
    report=json.loads(result.read_text())
    print(json.dumps(report,ensure_ascii=True,indent=2),flush=True)
    if not report['passed']:raise RuntimeError('UIKit fixture regressions failed')
finally:
    subprocess.run(['xcrun','simctl','shutdown',device],capture_output=True,timeout=60)
    subprocess.run(['xcrun','simctl','delete',device],capture_output=True,timeout=60)
