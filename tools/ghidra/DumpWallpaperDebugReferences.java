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
import ghidra.program.model.symbol.Symbol;
import ghidra.program.model.symbol.SymbolIterator;
import ghidra.program.model.symbol.SymbolTable;

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

    private static final String[] SYMBOL_TERMS = {
        "WallpaperTypes0A19DebugRequestMessage",
        "WallpaperTypes0A12DebugRequest",
        "WallpaperTypes0A13DebugResponse",
        "WallpaperTypes0A12DebugService",
        "WallpaperExtensionKit0aB5ProxyC18handleDebugRequest",
        "XPC11XPCListener",
        "IncomingSessionRequest",
        "XPC18XPCReceivedMessageV6decode",
        "XPC18XPCReceivedMessageV12handoffReply",
        "XPC18XPCReceivedMessageV5reply",
        "AgentXPCProtocol",
        "ensureViewModelIsUpToDate",
        "snapshotAllSpaces",
        "diagnosticState",
    };

    @Override
    public void run() throws Exception {
        Listing listing = currentProgram.getListing();
        FunctionManager functions = currentProgram.getFunctionManager();
        ReferenceManager references = currentProgram.getReferenceManager();
        SymbolTable symbolTable = currentProgram.getSymbolTable();

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

        SymbolIterator symbolIterator = symbolTable.getAllSymbols(true);
        while (symbolIterator.hasNext() && !monitor.isCancelled()) {
            Symbol symbol = symbolIterator.next();
            String name = symbol.getName(true);
            if (!matchesSymbolTerm(name)) {
                continue;
            }

            println("SYMBOL " + symbol.getAddress() + ": " + name);

            ReferenceIterator referenceIterator = references.getReferencesTo(symbol.getAddress());
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

    private boolean matchesSymbolTerm(String text) {
        for (String term : SYMBOL_TERMS) {
            if (text.contains(term)) {
                return true;
            }
        }
        return false;
    }
}
