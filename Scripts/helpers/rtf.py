from dataclasses import dataclass, field
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
    
    def read_word(self) -> str:
        w = ''
        while (c := self.peek()) and c.isalpha():
            w += c
            self.skip()
        return w

    def read_int(self) -> int:
        d = ''
        if (c := self.peek()) and c == '-':
            d += c
            self.skip()
        while (c := self.peek()) and c.isnumeric():
            d += c
            self.skip()
        return int(d)

@dataclass
class RTFControlWord:
    name: str
    value: Optional[int] = None

    @classmethod
    def parse_from(cls, r: RTFReader) -> Self:
        r.expect('\\')
        name = r.read_word()
        if r.peek().isnumeric():
            value = r.read_int()
        else:
            value = None
        return cls(name=name, value=value)
    
    def __str__(self) -> str:
        return f"\\{self.name}{str(self.value) if self.value is not None else ''}"

@dataclass
class RTFGroup:
    elements: list['RTFNode'] = field(default_factory=list)

    @classmethod
    def parse_from(cls, r: RTFReader) -> Self:
        elements = []
        r.expect('{')
        while r.peek() != '}':
            elements.append(RTFNode.parse_from(r))
        r.skip()
        return cls(elements)

    @classmethod
    def parse(cls, s: str) -> Self:
        return cls.parse_from(RTFReader(s))
    
    def __str__(self) -> str:
        return f"{{{''.join(map(str, self.elements))}}}"

@dataclass
class RTFText:
    value: str

    @classmethod
    def parse_from(cls, r: RTFReader) -> Self:
        value = ''
        while (c := r.peek()) and c not in {'\\', '{', '}'}:
            value += c
            r.skip()
        return cls(value)
    
    def __str__(self) -> str:
        return self.value

@dataclass
class RTFNode:
    value: RTFControlWord | RTFGroup | RTFText

    @classmethod
    def parse_from(cls, r: RTFReader) -> Self:
        match r.peek():
            case '\\': return cls(RTFControlWord.parse_from(r))
            case '{': return cls(RTFGroup.parse_from(r))
            case _: return cls(RTFText.parse_from(r))
    
    def __str__(self) -> str:
        return str(self.value)
