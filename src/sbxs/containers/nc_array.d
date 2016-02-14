/**
 * Array-like container for non-copiable objects.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.containers.nc_array;

import std.experimental.allocator.mallocator;


/**
 * A dynamic, array-like container, made to store non-copiable objects.
 *
 * Memory for new elements is allocated as needed using an allocator
 * passed as a compile-time parameter (`Mallocator`, bu default). When
 * more memory is needed, the capacity will at least double, in order to
 * provide "amortized constant time" inserts.
 *
 * Warning: As elements are inserted and removed, memory may have to be
 *     reallocated, and the data stored in a `NCArray` may move to
 *     different memory addresses. This will invalidate pointers to data
 *     stored in the array. Also, if the objects stored have pointers to
 *     their own internal data, these pointers will become invalid, too.
 *
 *     If you `reserve()` enough memory for all the objects you may ever need
 *     to store, and never remove anything, pointers should remain valid.
 *     So, either do this or be very careful with your pointers.
 *
 * Parameters:
 *     T = The type stored in this `Array`.
 *     Allocator = The allocator used to manage the memory.
 *
 * TODO: I implemented just the bare minimum required for my immediate needs. A
 *       decent, really reusable implementation needs much more stuff.
 */
public struct NCArray(T, Allocator = Mallocator)
{
    import std.conv: emplace;

    // If the stored are non-copiable, it doesn't hurt to explicit that the
    // `NCArray` itself os non-copiable, too.
    @disable this(this);

    /// Destroys the `RCAArray` and all values contained within it.
    public ~this()
    {
        auto m = cast(T*)_memory;
        for (size_t i; i < _length; ++i)
            destroy(m[i]);

        _allocator.deallocate(_memory);
    }

    /**
     * Creates and inserts an object at the end of the array.
     *
     * Parameters:
     *     args = The arguments passed to the object contructor.
     */
    public void insertBack(Args...)(Args args)
    {
        if (_length == _capacity)
        {
            if (_capacity == 0)
                reserve(1);
            else
                reserve(_capacity * 2);
        }

        // Use emplace() to avoid calling the destructor for an object that
        // isn't. (I mean, we don't want to call the destructor on the
        // non-object previously located at `_length + 1`).
        auto m = cast(T*)_memory;
        emplace(&m[_length++], args);
    }

    /**
     * Removes the object at `index`.
     *
     * All objects beyond `index` are moved, so that the array data remains
     * contiguous. The destructor for the object at `index` is called.
     *
     * Tests for out-of-bounds index only in debug time, with an `assert()`.
     */
    public void removeAt(size_t index)
    in
    {
        assert(index < _length);
    }
    body
    {
        import core.stdc.string: memmove;

        auto m = cast(T*)_memory;
        destroy(m[index]);

        const bytes = T.sizeof * (_length - index - 1);

        if (bytes > 0)
            memmove(&m[index], &m[index+1], bytes);

        --_length;
    }

    /**
     * Returns the value at a given index.
     *
     * The value is returned by reference, since we cannot copy it.
     *
     * Tests for out-of-bounds index only in debug time, with an `assert()`.
     *
     * Parameters:
     *     index = The desired index.
     *
     * Returns: The value at `index`.
     */
    public ref T opIndex(size_t index)
    in
    {
        assert(index < _length);
    }
    body
    {
        auto m = cast(T*)_memory;
        return m[index];
    }

    /// Provides a way to iterate over the array elements.
    public int opApply(int delegate(ref T) dg)
    {
        int result = 0;
        auto m = cast(T*)_memory;

        for (size_t i = 0; i < _length; ++i)
        {
            result = dg(m[i]);
            if (result)
                break;
        }

        return result;
    }

    /**
     * Reserves enough memory for `newCapacity` elements.
     *
     * Throws:
     *    `core.exception.OutOfMemoryError` if we run out of memory.
     */
    public void reserve(size_t newCapacity)
    {
        if (newCapacity > _capacity)
        {
            import core.exception: OutOfMemoryError;

            _capacity = newCapacity;
            const bytes = T.sizeof * _capacity;
            if (!_allocator.reallocate(_memory, bytes))
                throw new OutOfMemoryError();
        }
    }

    /// The memory where the data is stored.
    private void[] _memory;

    /**
     * The capacity of this `RCAArray`, that is, the number of elements it can
     * store before reallocating memory.
     */
    private size_t _capacity = 0;

    /// Ditto
    public @property size_t capacity() const { return _capacity; }

    /// The number of elements currently stored in this `RCAArray`.
    private size_t _length = 0;

    /// Ditto
    public @property size_t length() const { return _length; }

    /// The allocator used to manage the memory.
    private static shared Allocator _allocator;
}


///
unittest
{
    // A non-copiable type.
    struct NCT
    {
        @disable this(this);
        this(int data) { this.data = data; }
        int data;
    }

    // The array is initially empty
    NCArray!NCT ncArray;
    assert(ncArray.length == 0);

    // Insert some elements
    ncArray.insertBack(1000);
    ncArray.insertBack(1001);
    ncArray.insertBack(1002);
    assert(ncArray[0].data == 1000);
    assert(ncArray[1].data == 1001);
    assert(ncArray[2].data == 1002);
    assert(ncArray.length == 3);

    // Remove an element
    ncArray.removeAt(1); // destructor would be called if `NCT` had one
    assert(ncArray[0].data == 1000);
    assert(ncArray[1].data == 1002);
    assert(ncArray.length == 2);

    // If `NCT` had a destructor, the destructors for all the elements in the
    // array would be called when the array itself went out of scope.
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Iterate over an `NCArray`
unittest
{
    struct NCT
    {
        @disable this(this);
        this(int data) { this.data = data; }
        int data;
    }

    NCArray!NCT ncArray;
    ncArray.insertBack(10);
    ncArray.insertBack(11);
    ncArray.insertBack(12);
    ncArray.insertBack(13);
    ncArray.insertBack(14);

    // Iterate over the whole array
    int i = 0;
    foreach(ref nct; ncArray)
    {
        if (i == 0)
            assert(nct.data == 10);
        else if (i == 1)
            assert(nct.data == 11);
        else if (i == 2)
            assert(nct.data == 12);
        else if (i == 3)
            assert(nct.data == 13);
        else if (i == 4)
            assert(nct.data == 14);

        ++i;
    }

    // Iterate again, leaving before finishing
    i = 0;
    foreach(ref nct; ncArray)
    {
        if (i == 0)
            assert(nct.data == 10);
        else if (i == 1)
            assert(nct.data == 11);
        else
            break;

        ++i;
    }
}


// Ensure that destructors are properly called.
unittest
{
    struct NCT
    {
        @disable this(this);
        ~this() { ++numDestructorsCalled; }
        static int numDestructorsCalled = 0;
    }

    {
        NCArray!NCT ncArray;
        ncArray.insertBack();
        ncArray.insertBack();
        ncArray.insertBack();
        ncArray.insertBack();
        assert(NCT.numDestructorsCalled == 0);

        ncArray.removeAt(1);
        assert(NCT.numDestructorsCalled == 1);
    }

    assert(NCT.numDestructorsCalled == 4);
}


// Try `removeAt()`, including corner cases.
unittest
{
    struct NCT
    {
        @disable this(this);
        this(int data) { this.data = data; }
        int data;
    }

    NCArray!NCT ncArray;
    ncArray.insertBack(10);
    ncArray.insertBack(11);
    ncArray.insertBack(12);
    ncArray.insertBack(13);
    ncArray.insertBack(14);
    ncArray.insertBack(15);

    assert(ncArray.length == 6);

    // Remove from the end
    ncArray.removeAt(ncArray.length() - 1);
    assert(ncArray.length == 5);
    assert(ncArray[0].data == 10);
    assert(ncArray[1].data == 11);
    assert(ncArray[2].data == 12);
    assert(ncArray[3].data == 13);
    assert(ncArray[4].data == 14);

    // Remove from the beginning
    ncArray.removeAt(0);
    assert(ncArray.length == 4);
    assert(ncArray[0].data == 11);
    assert(ncArray[1].data == 12);
    assert(ncArray[2].data == 13);
    assert(ncArray[3].data == 14);

    // Remove from the middle
    ncArray.removeAt(1);
    assert(ncArray.length == 3);
    assert(ncArray[0].data == 11);
    assert(ncArray[1].data == 13);
    assert(ncArray[2].data == 14);
}


// Do some `reserve()` and `capacity` testing.
unittest
{
    struct NCT { @disable this(this); }

    NCArray!NCT ncArray;

    // Capacity must be initially zero
    assert(ncArray.capacity == 0);

    // Reserve memory for two elements
    ncArray.reserve(2);
    assert(ncArray.capacity == 2);

    // Insert two elements, capacity shouldn't change
    ncArray.insertBack();
    ncArray.insertBack();
    assert(ncArray.capacity == 2);

    // Insert one more element, capacity should have at least doubled
    ncArray.insertBack();
    assert(ncArray.capacity >= 4);
}

// Try to `reserve()` insane amounts of memory, to check if `OutOfMemoryErrors`
// are thrown.
unittest
{
    import std.exception: assertThrown;
    import core.exception: OutOfMemoryError;

    void newHugeArray()
    {
        NCArray!real array;
        array.reserve(size_t.max);
    }

    assertThrown!OutOfMemoryError(newHugeArray());
}
