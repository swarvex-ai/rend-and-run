"""Original, deterministic periodic industrial loops. CC0-1.0; no samples/providers."""
import numpy as np, wave, json, hashlib, os
from pathlib import Path
out=Path(os.environ['AMBIENCE_OUTPUT']);out.mkdir(parents=True,exist_ok=True)
rate=48000;duration=10;n=rate*duration;t=np.arange(n)/rate;freq=np.fft.rfftfreq(n,1/rate)
def air(seed,low,high):
 rng=np.random.default_rng(seed);spectrum=np.fft.rfft(rng.normal(size=n))
 response=(freq/(freq+low))**3/(1+(freq/high)**4)/np.sqrt(np.maximum(freq,40))
 x=np.fft.irfft(spectrum*response,n=n);return x/max(np.std(x),1e-12)
factory=.20*air(24,65,950)*(1+.05*np.sin(2*np.pi*.2*t))
for hz,amp in [(50,.43),(100,.16),(150,.075),(300,.035)]:factory+=amp*np.sin(2*np.pi*hz*t+.3)
server=.28*air(25,220,2600)*(1+.045*np.sin(2*np.pi*.3*t+.8))
for hz,amp in [(95,.15),(190,.065),(570,.018)]:server+=amp*np.sin(2*np.pi*hz*t+.8)
report={'license':'CC0-1.0','provenance':'Original deterministic synthesis; no sampled external recording, AI provider or paid call','sample_rate':rate,'duration_seconds':duration,'channels':1,'format':'PCM16','files':[]}
for name,x in [('factory_ventilation',factory),('server_fans',server)]:
 x=x-x.mean();x*=10**(-12/20)/np.max(np.abs(x));pcm=np.rint(x*32767).astype('<i2');p=out/(name+'.wav')
 with wave.open(str(p),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(pcm.tobytes())
 steps=np.abs(np.diff(pcm.astype(float)));seam=abs(float(pcm[0])-float(pcm[-1]));assert seam<=np.percentile(steps,99.9)+1
 report['files'].append({'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'samples':n,'peak_dbfs':float(20*np.log10(np.max(abs(pcm.astype(float)))/32768)),'rms_dbfs':float(20*np.log10(np.sqrt(np.mean((pcm.astype(float)/32768)**2)))),'seam_step_lsb':seam,'adjacent_step_p999_lsb':float(np.percentile(steps,99.9)),'periodic_construction':True})
(out/'manifest.json').write_text(json.dumps(report,indent=2)+'\n')
