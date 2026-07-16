// Print functions that reference the WallpaperAgent debug and runtime strings.
// @category Spelunking.WallpaperAgent
// @description Print functions that reference the WallpaperAgent debug and runtime strings.

import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.DataIterator;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceIterator;
import ghidra.program.model.symbol.ReferenceManager;
import ghidra.program.model.symbol.Symbol;
import ghidra.program.model.symbol.SymbolIterator;

public class DumpWallpaperDebugReferences extends GhidraScript {
    private static final String[] TERMS = {
        "WallpaperDebug",
        "debug.listener",
        "debug.service",
        "invalidateSnapshots",
        "updateRuntimeState",
        "handleGenerationChange",
        "Request reload due to wallpaper runtime change",
        "snapshotAllSpaces",
        "diagnosticState"
    };

    private static final String[] IMPORTS = { "signal", "sigaction", "exit" };

    @Override
    public void run() throws Exception {
        DataIterator dataIterator = currentProgram.getListing().getDefinedData(true);
        FunctionManager functions = currentProgram.getFunctionManager();
        ReferenceManager references = currentProgram.getReferenceManager();

        while (dataIterator.hasNext() && !monitor.isCancelled()) {
            Data data = dataIterator.next();
            Object value = data.getValue();
            if (value == null) {
                continue;
            }

            String text = String.valueOf(value);
            if (!containsTargetTerm(text)) {
                continue;
            }

            println("STRING " + data.getAddress() + ": " + text);
            ReferenceIterator referenceIterator = references.getReferencesTo(data.getAddress());
            while (referenceIterator.hasNext()) {
                Reference reference = referenceIterator.next();
                Function function = functions.getFunctionContaining(reference.getFromAddress());
                String functionName = function == null ? "<no containing function>" : function.getName();
                println("  " + reference.getReferenceType() + " -> " + functionName + " at " + reference.getFromAddress());
            }
        }

        for (String importedName : IMPORTS) {
            SymbolIterator symbols = currentProgram.getSymbolTable().getSymbols(importedName);
            while (symbols.hasNext()) {
                Symbol symbol = symbols.next();
                println("IMPORTED SYMBOL " + importedName + " at " + symbol.getAddress());
                printReferences(references, functions, symbol.getAddress());
            }
        }
    }

    private boolean containsTargetTerm(String text) {
        for (String term : TERMS) {
            if (text.contains(term)) {
                return true;
            }
        }
        return false;
    }

    private void printReferences(
        ReferenceManager references,
        FunctionManager functions,
        ghidra.program.model.address.Address address
    ) {
        ReferenceIterator referenceIterator = references.getReferencesTo(address);
        while (referenceIterator.hasNext()) {
            Reference reference = referenceIterator.next();
            Function function = functions.getFunctionContaining(reference.getFromAddress());
            String functionName = function == null ? "<no containing function>" : function.getName();
            println("  " + reference.getReferenceType() + " -> " + functionName + " at " + reference.getFromAddress());
        }
    }
}
