/* Private file recognition: only recognition software is downloaded; files never leave this browser. */
(function(root){
  'use strict';
  const base=new URL('.',document.currentScript.src);
  const libraries={
    'tesseract.js':'https://cdn.jsdelivr.net/npm/tesseract.js@6.0.1/',
    'tesseract.js-core':'https://cdn.jsdelivr.net/npm/tesseract.js-core@6.0.0/',
    'tesseract.js-data-eng':'https://cdn.jsdelivr.net/npm/@tesseract.js-data/eng@1.0.0/',
    'pdfjs-dist':'https://cdn.jsdelivr.net/npm/pdfjs-dist@6.3.289/',
    'heic2any':'https://cdn.jsdelivr.net/npm/heic2any@0.0.4/'
  };
  const asset=path=>{
    if(path.startsWith('vendor/')){const [,name,...rest]=path.split('/');return new URL(rest.join('/'),libraries[name]).href;}
    return new URL(path,base).href;
  };
  const loads=new Map();
  function script(path){
    if(!loads.has(path))loads.set(path,new Promise((resolve,reject)=>{
      const s=document.createElement('script');s.src=asset(path);s.onload=resolve;s.onerror=()=>{loads.delete(path);s.remove();reject(Error('The local reader could not load. Check your connection, or paste transaction text.'));};document.head.append(s);
    }));
    return loads.get(path);
  }
  async function read(file,type,progress=()=>{}){
    if(!file||file.size>20*1024*1024)throw Error('Choose a file up to 20 MB.');
    let worker,pdf,pdfTask;
    async function recognize(image){
      if(!worker){
        progress('Preparing the private reader. The first use may take a moment…');
        await script('vendor/tesseract.js/dist/tesseract.min.js');
        worker=await Tesseract.createWorker('eng',1,{
          workerPath:asset('vendor/tesseract.js/dist/worker.min.js'),
          corePath:asset('vendor/tesseract.js-core/'),
          langPath:asset('vendor/tesseract.js-data-eng/4.0.0/'),
          workerBlobURL:true,
          logger:m=>{if(m.status==='recognizing text')progress('Reading on your device… '+Math.round(m.progress*100)+'%');}
        });
      }
      let timer;
      try{return (await Promise.race([worker.recognize(image),new Promise((_,reject)=>{timer=setTimeout(()=>reject(Error('Reading took too long. Try a smaller or clearer file, or paste transaction text.')),120000);})])).data.text;}
      finally{clearTimeout(timer);}
    }
    try{
      if(type==='application/pdf'){
        progress('Reading PDF on your device…');
        const lib=await import(asset('vendor/pdfjs-dist/build/pdf.mjs'));
        lib.GlobalWorkerOptions.workerSrc=asset('vendor/pdfjs-dist/build/pdf.worker.mjs');
        pdfTask=lib.getDocument({data:new Uint8Array(await file.arrayBuffer()),isEvalSupported:false,wasmUrl:asset('vendor/pdfjs-dist/wasm/'),standardFontDataUrl:asset('vendor/pdfjs-dist/standard_fonts/'),cMapUrl:asset('vendor/pdfjs-dist/cmaps/'),cMapPacked:true});
        pdf=await pdfTask.promise;
        if(pdf.numPages>20)throw Error('Choose a PDF with 1–20 pages. Nothing was saved.');
        const pages=[];
        for(let n=1;n<=pdf.numPages;n++){
          progress('Reading PDF page '+n+' of '+pdf.numPages+' on your device…');
          const page=await pdf.getPage(n),content=await page.getTextContent();
          const rows=[];
          for(const item of content.items){
            if(!item.str?.trim())continue;
            const y=item.transform[5];let row=rows.find(r=>Math.abs(r.y-y)<3);
            if(!row){row={y,items:[]};rows.push(row);}row.items.push({x:item.transform[4],text:item.str});
          }
          let text=rows.sort((a,b)=>b.y-a.y).map(r=>r.items.sort((a,b)=>a.x-b.x).map(i=>i.text).join(' ')).join('\n');
          if(!root.SpendingCore.parse(text,new Date().getFullYear()+'-01').length){
            const initial=page.getViewport({scale:1});const scale=Math.min(2,2400/Math.max(initial.width,initial.height));
            const viewport=page.getViewport({scale}),canvas=document.createElement('canvas');canvas.width=Math.ceil(viewport.width);canvas.height=Math.ceil(viewport.height);
            try{await page.render({canvasContext:canvas.getContext('2d'),viewport}).promise;text=await recognize(canvas);}finally{canvas.width=canvas.height=0;}
          }
          pages.push(text);page.cleanup();
        }
        return pages.join('\n');
      }
      let image=file;
      if(type==='image/heic'||type==='image/heif'){
        progress('Converting HEIC on your device…');await script('vendor/heic2any/dist/heic2any.min.js');
        image=await heic2any({blob:file,toType:'image/png'});if(Array.isArray(image))image=image[0];
      }
      return await recognize(image);
    }catch(err){
      if(err?.name==='PasswordException')throw Error('This PDF is password-protected. Use an unlocked copy or enter transactions manually.');
      throw Error(err?.message||'This file could not be read. Try a JPG, PNG, HEIC, or PDF, or paste transaction text.');
    }finally{if(worker)await worker.terminate();if(pdfTask)await pdfTask.destroy();}
  }
  root.PrivateImport={read};
})(window);
