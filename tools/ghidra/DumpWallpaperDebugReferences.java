// Prints functions that reference WallpaperAgent debug and runtime strings.
//@category Spelunking.WallpaperAgent

import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.DataIterator;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.listing.Listing;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceIterator;
import ghidra.program.model.symbol.ReferenceManager;

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
        "diagnosticState",
        "ensureViewModelIsUpToDate",
    };

    @Override
    public void run() throws Exception {
        Listing listing = currentProgram.getListing();
        FunctionManager functions = currentProgram.getFunctionManager();
        ReferenceManager references = currentProgram.getReferenceManager();

        DataIterator iterator = listing.getDefinedData(true);
        while (iterator.hasNext() && !monitor.isCancelled()) {
            Data data = iterator.next();
            Object value = data.getValue();
            if (value == null) {
                continue;
            }

            String text = value.toString();
            if (!matchesTerm(text)) {
                continue;
            }

            println("STRING " + data.getAddress() + ": " + text);

            ReferenceIterator referenceIterator = references.getReferencesTo(data.getAddress());
            while (referenceIterator.hasNext() && !monitor.isCancelled()) {
                Reference reference = referenceIterator.next();
                Function function = functions.getFunctionContaining(reference.getFromAddress());
                String functionName = function == null ? "<no containing function>" : function.getName();
                println("  " + reference.getReferenceType() + " -> " + functionName + " at " + reference.getFromAddress());
            }
        }
    }

    private boolean matchesTerm(String text) {
        for (String term : TERMS) {
            if (text.contains(term)) {
                return true;
            }
        }
        return false;
    }
}
