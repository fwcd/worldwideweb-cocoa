from typing import Optional, Self

# Based on https://www.biblioscape.com/rtf15_spec.htm

class RTFParseError(Exception):
    pass

class RTFReader:
    def __init__(self, raw_str: str, i: int = 0):
        self.raw_str = raw_str
        self.i = i
    
    def child(self) -> Self:
        return RTFReader(self.raw_str, self.i)

    def peek(self, n: int = 1) -> str:
        if self.i + n > len(self.raw_str):
            raise RTFParseError(f'RTF file ended too early, could not read next {n} char(s)')

        return self.raw_str[self.i:self.i + n]

    def skip(self, n: int = 1):
        self.i += n

    def next(self, n: int = 1) -> str:
        s = self.peek(n)
        self.skip(n)
        return s

    def expect(self, expected: str):
        s = self.next(len(expected))
        if s != expected:
            raise RTFParseError(f"Expected '{expected}', but got '{s}'")
    
    def read_int(self) -> int:
        d = ''
        if (c := self.peek()) and c == '-':
            d += c
            self.skip()
        while (c := self.peek()) and c.isnumeric():
            d += c
            self.skip()
        return int(d)
    
    def read_control_word(self) -> str:
        self.expect('\\')
        cw = ''
        while (c := self.peek()) and c.isalpha():
            cw += c
            self.skip()
        return cw

    def peek_control_word(self) -> Optional[str]:
        if self.peek() != '\\':
            return None
        return self.child().read_control_word()
    
    def ignore_int(self):
        if self.peek().isnumeric():
            self.read_int()

    def ignore_control_word(self, ignored: str) -> str:
        cw = self.peek_control_word()
        if cw == ignored:
            self.skip(len(cw))
            self.ignore_int()

    def expect_control_word(self, expected: str) -> str:
        cw = self.read_control_word()
        if cw != expected:
            raise RTFParseError(f'Expected control word \\{expected}, but got \\{cw}')

class RTFFontTable:
    @classmethod
    def parse_from(cls, reader: RTFReader) -> Self:
        self = cls()

        return self

class RTFHeader:
    @classmethod
    def parse_from(cls, reader: RTFReader) -> Self:
        self = cls()

        reader.expect_control_word('rtf')
        self.rtf_version = reader.read_int()
        self.charset = reader.read_control_word()

        reader.ignore_control_word('deff')

        self.font_table = RTFFontTable.parse

        return self

class RTFDocument:
    @classmethod
    def parse_from(cls, reader: RTFReader) -> Self:
        self = cls()

        # TODO

        return self

class RTF:
    '''An Rich Text Format (RTF) file.'''

    @classmethod
    def parse_from(cls, reader: RTFReader) -> Self:
        self = cls()
        reader.expect('{')

        self.header = RTFHeader.parse_from(reader)
        self.document = RTFDocument.parse_from(reader)

        reader.expect('}')
        return self
    
    @classmethod
    def parse(cls, s: str) -> Self:
        cls.parse_from(RTFReader(s))
