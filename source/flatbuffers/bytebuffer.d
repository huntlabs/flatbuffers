/*
 * Copyright 2016 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module flatbuffers.bytebuffer;

import std.exception;
import std.bitmanip;
import std.exception;
import core.exception;

/**
    Class warp a ubyte[] to provide byte handle.
*/

final class ByteBuffer
{
public:
	this(){}

    /// init ByteBuffer obj with buffer data
    this(ubyte[] buffer)
    {
		restData(buffer,0);
    }

    /// Returns buffer length
    @property size_t length()
    {
        return _buffer.length;
    }

    /// Returns buffer data
    @property ubyte[] data()
    {
        return _buffer;
    }

    /// Returns buffer position
    @property size_t position()
    {
        return _pos;
    }
    /// put boolen value into buffer
    void put(T)(size_t offset, T value) if (is(T == bool))
    {
        put!ubyte(offset, (value ? 0x01 : 0x00));
    }

    /// put byte value into buffer
	void put(T)(size_t offset, T value) if (isByte!T)
    {
        mixin(verifyOffset!1);
        _buffer[offset] = value;
        _pos = offset;
    }

    /// put numbirc value into buffer
	void put(T)(size_t offset, T value) if (isNum!T)
    {
        mixin(verifyOffset!(T.sizeof));
        version (FLATBUFFER_BIGENDIAN)
        {
            auto array = nativeToBigEndian!T(value);
            _buffer[offset .. (offset + T.sizeof)] = array[];
        }
        else
        {
            auto array = nativeToLittleEndian!T(value);
            _buffer[offset .. (offset + T.sizeof)] = array[];
        }
        _pos = offset;
    }

    ///get Byte value in buffer from index
    T get(T)(size_t index) if (isByte!T)
    {
        return cast(T) _buffer[index];
    }

	T get(T)(size_t index) if(is(T == bool))
    {
        ubyte value = get!ubyte(index);
        return (value ==0x01 ? true : false);
    }

	T get(T)(size_t index) if (isNum!T)
    {
        ubyte[T.sizeof] buf = _buffer[index .. (index + T.sizeof)];
        version (FLATBUFFER_BIGENDIAN)
            return bigEndianToNative!(T, T.sizeof)(buf);
        else
            return littleEndianToNative!(T, T.sizeof)(buf);
    }

	void restData(ubyte[] buffer,size_t pos){
		_buffer = buffer;
		_pos = pos;
	}

private: /// Variables.
    ubyte[] _buffer;
    size_t _pos; /// Must track start of the buffer.
}

unittest
{
    ByteBuffer buf = new ByteBuffer(new ubyte[50]);
    int a = 10;
    buf.put(5, a);
    short t = 4;
    buf.put(9, t);

    assert(buf.get!int(5) == 10);
    assert(buf.get!short(9) == 4);

}
/***********************************
 * test for boolen value
 */
unittest
{
    ByteBuffer buf = new ByteBuffer(new ubyte[50]);
    bool a = true;
    buf.put(5, a);
    bool b = false;
    buf.put(9, b);
    assert(buf.get!bool(5) == true);
    assert(buf.get!bool(9) == false);

}
private:
template verifyOffset(size_t length)
{
    enum verifyOffset = "if(offset < 0 || offset >= _buffer.length || (offset + " ~ length.stringof ~ ") > _buffer.length) throw new RangeError();";
}

template isNum(T)
{
    static if (is(T == short) || is(T == ushort) || is(T == int) || is(T == uint)
            || is(T == long) || is(T == ulong) || is(T == float) || is(T == double))
        enum isNum = true;
    else
        enum isNum = false;
}

template isByte(T)
{
    static if (is(T == byte) || is(T == ubyte))
        enum isByte = true;
    else
        enum isByte = false;
}
