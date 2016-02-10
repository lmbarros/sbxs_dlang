/**
 * Signals, as in "Signals and Slots".
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros
 */

module sbxs.util.signal;


/**
 * The type representing a slot ID.
 *
 * In this implementation, every slot connected to a signal has an ID that
 * identifies it uniquely. This is type of these IDs.
 */
public alias size_t slotID;


/// A slot ID that is guaranteed to be different to any real slot ID.
public enum invalidSlotID = 0;


/**
 * Yet another implementation of signals (as in "Signals and Slots").
 *
 * I tested other implementations which were nicer than this one in several
 * aspects, but were much slower (orders of magnitude slower) than this approach
 * I have here. Since this libraru relies heavily on event handlers, I judged
 * that any additional cumbersomeness is well worth in this case.
 *
 * This implementation doesn't do anything to be thread safe (which probably
 * explains to a large extent why it is faster than other implementations).
 *
 * Parameters:
 *     Params = The parameters that are accepted by the slots connecting to this
 *         signal. (Notice that the slots must return `void`.)
 */
public struct Signal(Params...)
{
    /**
     * The type of slots that can connect to this signal. (Notice that the slots
     * must always return `void`.)
     */
    public alias slot_t = void delegate(Params);

    /**
     * Connects a slot to this signal.
     *
     * Parameters:
     *    slot = The slot to connect.
     *
     * Returns:
     *    An ID that can be later passed to `disconnect()` in order to remove
     *    the slot just added.
     */
    public slotID connect(slot_t slot) @safe
    {
        const id = _nextSlotID++;
        _slots[id] = slot;
        return id;
    }

    /**
     * Disconnects a slot from this signal.
     *
     * Parameters:
     *     id = The ID of the slot to remove. If there is no slot with this ID,
     *         nothing happens. (Corollary: it is OK to pass `invalidSlotID` to
     *         this method; nothing will happen.)
     *
     * Returns:
     *     `true` if the slot was removed; `false` if not (which means that
     *     no slot with the given ID was found).
     */
    public bool disconnect(slotID id) @safe
    {
        return _slots.remove(id);
    }

    /**
     * Calls all slots added to this `Signal`.
     *
     * Parameters:
     *     params = The parameters to pass to the slots.
     *
     * Returns: `true` if at least one slot was called; `false` otherwise.
     */
    public bool emit(Params...)(Params params)
    {
        foreach (slot; _slots)
            slot(params);

        return _slots.length > 0;
    }

    /// Returns the number of slots currently connected to this signal.
    public @property size_t slotCount() @safe nothrow @nogc
    {
        return _slots.length;
    }

    /// The next ID to be returned by `connect()`.
    private slotID _nextSlotID = invalidSlotID + 1;

    /// The slots stored in the set, indexed by their IDs.
    private slot_t[slotID] _slots;
}


///
unittest
{
    alias void delegate(int x, string s) eventHandler_t;

    int theInt = 0;
    string theString;

    void handler1(int x, string s) @safe
    {
        theInt = 100 + x;
        theString = "1: " ~ s;
    }

    void handler2(int x, string s)
    {
        theInt += 200 + x;
        theString = "2: " ~ s;
    }

    void handler3(int x, string s)
    {
        theInt += 1_000_000;
    }

    Signal!(int, string) signal;

    // Connect a slot and call it
    const id1 = signal.connect(&handler1);
    signal.emit(5, "Hello");
    assert(theInt == 105);
    assert(theString == "1: Hello");

    // Remove the handler, add some more handlers, call them
    signal.disconnect(id1);
    const id2 = signal.connect(&handler2);
    const id3 = signal.connect(&handler3);

    theInt = 0;
    signal.emit(3, "Goodbye");
    assert(theInt == 1_000_203);
    assert(theString == "2: Goodbye");

    // Remove all handlers, call them again; nothing shall happen
    signal.disconnect(id2);
    signal.disconnect(id3);
    signal.emit(8, "Good night");
    assert(theInt == 1_000_203);
    assert(theString == "2: Goodbye");
}


// Tests methods connect(), disconnect() and slotCount()
unittest
{
    void aHandler(double, ulong) { }

    Signal!(double, ulong) signal;

    // Initially, no slots are connected
    assert(signal.slotCount == 0);

    // Connect some slots
    const id1 = signal.connect(&aHandler);
    const id2 = signal.connect(&aHandler);
    const id3 = signal.connect(&aHandler);

    // Ensure the IDs are the expected
    assert(id1 != invalidSlotID);
    assert(id2 == id1 + 1);
    assert(id3 == id1 + 2);

    // Now we should have some slots connected
    assert(signal.slotCount == 3);

    // Disconnect a slot, check the status again
    bool disconnected = signal.disconnect(id2);
    assert(disconnected);
    assert(signal.slotCount == 2);

    // Try disconnecting some nonexistent slots
    disconnected = signal.disconnect(invalidSlotID);
    assert(!disconnected);

    disconnected = signal.disconnect(id3 + 111);
    assert(!disconnected);

    // Now, remove the remaining two slots, re-check
    signal.disconnect(id1);
    signal.disconnect(id3);

    assert(signal.slotCount == 0);
}
