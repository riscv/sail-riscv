/*
Copyright (C) 2001-present by Serge Lamikhov-Center

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#ifndef ELFIO_SECTION_HPP
#define ELFIO_SECTION_HPP

#include <string>
#include <iostream>
#include <new>
#include <limits>

namespace ELFIO {

class section
{
    friend class elfio;

  public:
    virtual ~section() = default;

    ELFIO_GET_ACCESS_DECL( Elf_Half, index );
    ELFIO_GET_SET_ACCESS_DECL( std::string, name );
    ELFIO_GET_SET_ACCESS_DECL( Elf_Word, type );
    ELFIO_GET_SET_ACCESS_DECL( Elf_Xword, flags );
    ELFIO_GET_SET_ACCESS_DECL( Elf_Word, info );
    ELFIO_GET_SET_ACCESS_DECL( Elf_Word, link );
    ELFIO_GET_SET_ACCESS_DECL( Elf_Xword, addr_align );
    ELFIO_GET_SET_ACCESS_DECL( Elf_Xword, entry_size );
    ELFIO_GET_SET_ACCESS_DECL( Elf64_Addr, address );
    ELFIO_GET_SET_ACCESS_DECL( Elf_Xword, size );
    ELFIO_GET_SET_ACCESS_DECL( Elf_Word, name_string_offset );
    ELFIO_GET_ACCESS_DECL( Elf64_Off, offset );

    virtual const char* get_data() const                                   = 0;
    virtual void        set_data( const char* raw_data, Elf_Word size )    = 0;
    virtual void        set_data( const std::string& data )                = 0;
    virtual void        append_data( const char* raw_data, Elf_Word size ) = 0;
    virtual void        append_data( const std::string& data )             = 0;
    virtual void
    insert_data( Elf_Xword pos, const char* raw_data, Elf_Word size )    = 0;
    virtual void   insert_data( Elf_Xword pos, const std::string& data ) = 0;
    virtual size_t get_stream_size() const                               = 0;
    virtual void   set_stream_size( size_t value )                       = 0;

  protected:
    ELFIO_SET_ACCESS_DECL( Elf64_Off, offset );
    ELFIO_SET_ACCESS_DECL( Elf_Half, index );

    virtual bool load( std::istream&  stream,
                       std::streampos header_offset,
                       bool           is_lazy )               = 0;
    virtual void save( std::ostream&  stream,
                       std::streampos header_offset,
                       std::streampos data_offset ) = 0;
    virtual bool is_address_initialized() const     = 0;
};

template <class T> class section_impl : public section
{
  public:
    //------------------------------------------------------------------------------
    section_impl( const endianess_convertor*                    convertor,
                  const address_translator*                     translator,
                  const std::shared_ptr<compression_interface>& compression )
        : convertor( convertor ), translator( translator ),
          compression( compression )
    {
    }

    //------------------------------------------------------------------------------
    // Section info functions
    ELFIO_GET_SET_ACCESS( Elf_Word, type, header.sh_type );
    ELFIO_GET_SET_ACCESS( Elf_Xword, flags, header.sh_flags );
    ELFIO_GET_SET_ACCESS( Elf_Xword, size, header.sh_size );
    ELFIO_GET_SET_ACCESS( Elf_Word, link, header.sh_link );
    ELFIO_GET_SET_ACCESS( Elf_Word, info, header.sh_info );
    ELFIO_GET_SET_ACCESS( Elf_Xword, addr_align, header.sh_addralign );
    ELFIO_GET_SET_ACCESS( Elf_Xword, entry_size, header.sh_entsize );
    ELFIO_GET_SET_ACCESS( Elf_Word, name_string_offset, header.sh_name );
    ELFIO_GET_ACCESS( Elf64_Addr, address, header.sh_addr );
    //------------------------------------------------------------------------------
    Elf_Half get_index() const override { return index; }

    //------------------------------------------------------------------------------
    std::string get_name() const override { return name; }

    //------------------------------------------------------------------------------
    void set_name( const std::string& name_prm ) override
    {
        this->name = name_prm;
    }

    //------------------------------------------------------------------------------
    void set_address( const Elf64_Addr& value ) override
    {
        header.sh_addr = decltype( header.sh_addr )( value );
        header.sh_addr = ( *convertor )( header.sh_addr );
        is_address_set = true;
    }

    //------------------------------------------------------------------------------
    bool is_address_initialized() const override { return is_address_set; }

    //------------------------------------------------------------------------------
    const char* get_data() const override
    {
        if ( is_lazy ) {
            load_data();
        }
        return data.get();
    }

    //------------------------------------------------------------------------------
    void set_data( const char* raw_data, Elf_Word size ) override
    {
        if ( get_type() != SHT_NOBITS ) {
            data = std::unique_ptr<char[]>( new ( std::nothrow ) char[size] );
            if ( nullptr != data.get() && nullptr != raw_data ) {
                data_size = size;
                std::copy( raw_data, raw_data + size, data.get() );
            }
            else {
                data_size = 0;
            }
        }

        set_size( data_size );
        if ( translator->empty() ) {
            set_stream_size( data_size );
        }
    }

    //------------------------------------------------------------------------------
    void set_data( const std::string& str_data ) override
    {
        return set_data( str_data.c_str(), (Elf_Word)str_data.size() );
    }

    //------------------------------------------------------------------------------
    void append_data( const char* raw_data, Elf_Word size ) override
    {
        insert_data( get_size(), raw_data, size );
    }

    //------------------------------------------------------------------------------
    void append_data( const std::string& str_data ) override
    {
        return append_data( str_data.c_str(), (Elf_Word)str_data.size() );
    }

    //------------------------------------------------------------------------------
    void
    insert_data( Elf_Xword pos, const char* raw_data, Elf_Word size ) override
    {
        if ( get_type() != SHT_NOBITS ) {
            if ( get_size() + size < data_size ) {
                char* d = data.get();
                std::copy_backward( d + pos, d + get_size(),
                                    d + get_size() + size );
                std::copy( raw_data, raw_data + size, d + pos );
            }
            else {
                data_size = 2 * ( data_size + size );
                std::unique_ptr<char[]> new_data(
                    new ( std::nothrow ) char[data_size] );

                if ( nullptr != new_data ) {
                    char* d = data.get();
                    std::copy( d, d + pos, new_data.get() );
                    std::copy( raw_data, raw_data + size,
                               new_data.get() + pos );
                    std::copy( d + pos, d + get_size(),
                               new_data.get() + pos + size );
                    data = std::move( new_data );
                }
                else {
                    size = 0;
                }
            }
            set_size( get_size() + size );
            if ( translator->empty() ) {
                set_stream_size( get_stream_size() + size );
            }
        }
    }

    //------------------------------------------------------------------------------
    void insert_data( Elf_Xword pos, const std::string& str_data ) override
    {
        return insert_data( pos, str_data.c_str(), (Elf_Word)str_data.size() );
    }

    size_t get_stream_size() const override { return stream_size; }

    //------------------------------------------------------------------------------
    void set_stream_size( size_t value ) override { stream_size = value; }

    //------------------------------------------------------------------------------
  protected:
    //------------------------------------------------------------------------------
    ELFIO_GET_SET_ACCESS( Elf64_Off, offset, header.sh_offset );

    //------------------------------------------------------------------------------
    void set_index( const Elf_Half& value ) override { index = value; }

    bool is_compressed() const
    {
        return ( ( get_flags() & SHF_RPX_DEFLATE ) ||
                 ( get_flags() & SHF_COMPRESSED ) ) &&
               compression != nullptr;
    }

    //------------------------------------------------------------------------------
    bool load( std::istream&  stream,
               std::streampos header_offset,
               bool           is_lazy_ ) override
    {
        pstream = &stream;
        is_lazy = is_lazy_;

        if ( translator->empty() ) {
            stream.seekg( 0, std::istream::end );
            set_stream_size( size_t( stream.tellg() ) );
        }
        else {
            set_stream_size( std::numeric_limits<size_t>::max() );
        }

        stream.seekg( ( *translator )[header_offset] );
        stream.read( reinterpret_cast<char*>( &header ), sizeof( header ) );

        if ( !is_lazy || is_compressed() ) {

            bool ret = load_data();

            if ( is_compressed() ) {
                Elf_Xword size              = get_size();
                Elf_Xword uncompressed_size = 0;
                auto      decompressed_data = compression->inflate(
                         data.get(), convertor, size, uncompressed_size );
                if ( decompressed_data != nullptr ) {
                    set_size( uncompressed_size );
                    data = std::move( decompressed_data );
                }
            }

            return ret;
        }

        return true;
    }

    bool load_data() const
    {
        is_lazy        = false;
        Elf_Xword size = get_size();
        if ( nullptr == data && SHT_NULL != get_type() &&
             SHT_NOBITS != get_type() && size < get_stream_size() ) {
            data.reset( new ( std::nothrow ) char[size_t( size ) + 1] );

            if ( ( 0 != size ) && ( nullptr != data ) ) {
                pstream->seekg(
                    ( *translator )[( *convertor )( header.sh_offset )] );
                pstream->read( data.get(), size );
                if ( static_cast<Elf_Xword>( pstream->gcount() ) != size ) {
                    data = nullptr;
                    return false;
                }

                // refresh size because it may have changed if we had to decompress data
                size = get_size();
                data.get()[size] =
                    0; // Ensure data is ended with 0 to avoid oob read
                data_size = decltype( data_size )( size );
            }
            else {
                data_size = 0;
            }
        }

        return true;
    }

    //------------------------------------------------------------------------------
    void save( std::ostream&  stream,
               std::streampos header_offset,
               std::streampos data_offset ) override
    {
        if ( 0 != get_index() ) {
            header.sh_offset = decltype( header.sh_offset )( data_offset );
            header.sh_offset = ( *convertor )( header.sh_offset );
        }

        save_header( stream, header_offset );
        if ( get_type() != SHT_NOBITS && get_type() != SHT_NULL &&
             get_size() != 0 && data != nullptr ) {
            save_data( stream, data_offset );
        }
    }

    //------------------------------------------------------------------------------
  private:
    //------------------------------------------------------------------------------
    void save_header( std::ostream& stream, std::streampos header_offset ) const
    {
        adjust_stream_size( stream, header_offset );
        stream.write( reinterpret_cast<const char*>( &header ),
                      sizeof( header ) );
    }

    //------------------------------------------------------------------------------
    void save_data( std::ostream& stream, std::streampos data_offset )
    {
        adjust_stream_size( stream, data_offset );

        if ( ( ( get_flags() & SHF_COMPRESSED ) ||
               ( get_flags() & SHF_RPX_DEFLATE ) ) &&
             compression != nullptr ) {
            Elf_Xword decompressed_size = get_size();
            Elf_Xword compressed_size   = 0;
            auto      compressed_ptr    = compression->deflate(
                        data.get(), convertor, decompressed_size, compressed_size );
            stream.write( compressed_ptr.get(), compressed_size );
        }
        else {
            stream.write( get_data(), get_size() );
        }
    }

    //------------------------------------------------------------------------------
  private:
    mutable std::istream*                        pstream = nullptr;
    T                                            header  = {};
    Elf_Half                                     index   = 0;
    std::string                                  name;
    mutable std::unique_ptr<char[]>              data;
    mutable Elf_Word                             data_size      = 0;
    const endianess_convertor*                   convertor      = nullptr;
    const address_translator*                    translator     = nullptr;
    const std::shared_ptr<compression_interface> compression    = nullptr;
    bool                                         is_address_set = false;
    size_t                                       stream_size    = 0;
    mutable bool                                 is_lazy        = false;
};

} // namespace ELFIO

#endif // ELFIO_SECTION_HPP
