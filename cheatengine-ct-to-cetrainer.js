const fs = require('fs');
const xml2js = require('xml2js');
const path = require('path');

class CTToTrainerConverter {
  constructor() {
    this.parser = new xml2js.Parser();
    this.builder = new xml2js.Builder({
      xmldec: { version: '1.0', encoding: 'utf-8' }
    });
  }

  async convertFile(inputPath, outputPath, gameProcessName) {
    try {
      const xmlContent = fs.readFileSync(inputPath, 'utf-8');
      const result = await this.parser.parseStringPromise(xmlContent);
      
      const cleanedResult = this.cleanCheatTable(result);
      const cheatIds = this.extractCheatIds(cleanedResult);
      cleanedResult.CheatTable.LuaScript = [this.generateLuaScript(gameProcessName, cheatIds)];
      
      const xml = this.builder.buildObject(cleanedResult);
      fs.writeFileSync(outputPath, xml);
      
      console.log(`✅ Successfully converted ${inputPath} to ${outputPath}`);
      console.log(`📋 Found ${cheatIds.length} cheats: ${cheatIds.join(', ')}`);
      
    } catch (error) {
      console.error('❌ Error converting file:', error.message);
    }
  }

  cleanCheatTable(cheatTable) {
    // Remove Forms section
    if (cheatTable.CheatTable.Forms) {
      delete cheatTable.CheatTable.Forms;
    }

    // Remove hotkeys from all cheat entries
    if (cheatTable.CheatTable.CheatEntries) {
      this.removeHotkeysRecursive(cheatTable.CheatTable.CheatEntries);
    }

    return cheatTable;
  }

  removeHotkeysRecursive(entries) {
    if (!Array.isArray(entries)) return;

    entries.forEach(entryContainer => {
      if (entryContainer.CheatEntry) {
        entryContainer.CheatEntry.forEach(entry => {
          // Remove hotkeys
          if (entry.Hotkeys) {
            delete entry.Hotkeys;
          }
          
          // Remove UI options
          if (entry.Options) {
            delete entry.Options;
          }

          // Recursively process nested entries
          if (entry.CheatEntries) {
            this.removeHotkeysRecursive(entry.CheatEntries);
          }
        });
      }
    });
  }

  extractCheatIds(cheatTable) {
    const ids = [];
    
    if (cheatTable.CheatTable.CheatEntries) {
      this.extractIdsRecursive(cheatTable.CheatTable.CheatEntries, ids);
    }
    
    return ids;
  }

  extractIdsRecursive(entries, ids) {
    if (!Array.isArray(entries)) return;

    entries.forEach(entryContainer => {
      if (entryContainer.CheatEntry) {
        entryContainer.CheatEntry.forEach(entry => {
          if (entry.ID && entry.ID[0]) {
            ids.push(parseInt(entry.ID[0]));
          }

          // Recursively process nested entries
          if (entry.CheatEntries) {
            this.extractIdsRecursive(entry.CheatEntries, ids);
          }
        });
      }
    });
  }

  generateLuaScript(gameProcessName, cheatIds) {
    const cheatIdsString = cheatIds.map(id => `    ${id}`).join(',\n');
    
    return `-- Auto-enable all cheats trainer
-- Generated automatically from CT file

getAutoAttachList().add("${gameProcessName}")
hideAllCEWindows()

RequiredCEVersion=7.4
if (getCEVersion==nil) or (getCEVersion()<RequiredCEVersion) then
  messageDialog('Please install Cheat Engine '..RequiredCEVersion, mtError, mbOK)
  closeCE()
end

function onAttach()
  local addresslist = getAddressList()
  sleep(3000)
  
  -- Auto-enable all cheats
  local cheats = {
${cheatIdsString}
  }
  
  for i, cheatId in ipairs(cheats) do
    local memrec = addresslist.getMemoryRecordByID(cheatId)
    if memrec then
      memrec.Active = true
      sleep(100)
    end
  end
end

local al = getAutoAttachList()
al.OnAttach = onAttach

local form = createForm()
form.Width = 0
form.Height = 0
form.WindowState = wsMinimized
form.ShowInTaskbar = false
form.Visible = false
form.FormStyle = fsStayOnTop

createTimer(nil, function()
  if not isProcessActive("${gameProcessName}") then
    closeCE()
  end
end, 5000)`;
  }
}

// Command line usage
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length < 3) {
    console.log('Usage: node ct-to-trainer.js <input.CT> <output.CETRAINER> <game.exe>');
    console.log('Example: node ct-to-trainer.js witcher3.CT witcher3_auto.CETRAINER witcher3.exe');
    process.exit(1);
  }

  const [inputPath, outputPath, gameProcess] = args;
  const converter = new CTToTrainerConverter();
  converter.convertFile(inputPath, outputPath, gameProcess);
}

module.exports = CTToTrainerConverter;
