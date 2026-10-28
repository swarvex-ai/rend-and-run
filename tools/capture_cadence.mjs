#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import {spawnSync} from 'node:child_process';
const runDir=process.env.GAME_DEV_RUN_DIR;
if(!runDir)throw new Error('Run through game-dev scenario run');
// This Godot build only supports dummy rendering headlessly. Explicit local X11
// capture is declared windowless:false; the harness GPU authorization still applies.
const profile=await fs.mkdtemp(path.join(os.tmpdir(),'rendrun-cadence-'));
try {
 const result=spawnSync('/usr/bin/godot',['--path','game','--audio-driver','Dummy','--windowed','--resolution','960x540','--script','res://tests/attack_cadence_integration.gd'],{env:{...process.env,DISPLAY:':0',XAUTHORITY:process.argv[2],H65_OUTPUT:runDir,XDG_DATA_HOME:profile,XDG_CONFIG_HOME:'/tmp/rendrun-v10-config'},encoding:'utf8',timeout:80000,maxBuffer:4*1024*1024});
 process.stdout.write(result.stdout??'');process.stderr.write(result.stderr??'');
 if(result.error)throw result.error;
 if(result.status!==0)throw new Error('Godot exited '+result.status);
 const report=JSON.parse(await fs.readFile(path.join(runDir,'integration.json'),'utf8'));
 if(report.failures!==0)throw new Error('Cadence checks failed');
 await fs.writeFile(path.join(runDir,'capture.json'),JSON.stringify({schema:'game_dev.capture.v1',runId:process.env.GAME_DEV_RUN_ID,adapterId:process.env.GAME_DEV_ADAPTER_ID,scenarioId:process.env.GAME_DEV_SCENARIO_ID,sourceFormat:'game-dev-capture-v1',frames:['motion-4','motion-12','motion-28'].map((label,index)=>({index,label,attachments:[{kind:'color',path:label+'.png',encoding:'png'}]})),measurements:[],adapterEvidence:{windowless:false,graphicsApi:'Godot Forward+ Vulkan',notes:['Actual Godot viewport captures after RenderingServer.force_draw. Controlled opposing actors plus repeated autonomous attacks, not human playtest approval. No hardware timing measured. Cadence cases in integration.json.']}}));
}finally{await fs.rm(profile,{recursive:true,force:true});}
