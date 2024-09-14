from dataclasses import dataclass, field
from typing import Optional, Self

from helpers.reader import Reader

# Based on https://www.biblioscape.com/rtf15_spec.htm

# Lower level (unstructured) parsing

@dataclass
class RTFControlWord:
    name: str
    value: Optional[int] = None

    @classmethod
    def parse_from(cls, r: Reader[str]) -> Self:
        r.expect('\\')
        name = r.next_word()
        if r.peek().isnumeric():
            value = r.next_int()
        else:
            value = None
        return cls(name=name, value=value)
    
    def __str__(self) -> str:
        return f"\\{self.name}{str(self.value) if self.value is not None else ''}"

@dataclass
class RTFGroup:
    elements: list['RTFNode'] = field(default_factory=list)

    @classmethod
    def parse_from(cls, r: Reader[str]) -> Self:
        elements = []
        r.expect('{')
        while r.peek() != '}':
            elements.append(RTFNode.parse_from(r))
        r.skip()
        return cls(elements)

    def __str__(self) -> str:
        return f"{{{''.join(map(str, self.elements))}}}"

@dataclass
class RTFText:
    value: str

    @classmethod
    def parse_from(cls, r: Reader[str]) -> Self:
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
    def parse_from(cls, r: Reader[str]) -> Self:
        match r.peek():
            case '\\': return cls(RTFControlWord.parse_from(r))
            case '{': return cls(RTFGroup.parse_from(r))
            case _: return cls(RTFText.parse_from(r))
    
    def __str__(self) -> str:
        return str(self.value)

# Higher level (structured) parsing

@dataclass
class RTF:
    version: Optional[int] = None

    @classmethod
    def parse_from(cls, group: RTFGroup) -> Self:
        self = cls()

        # Parse header
        it = iter(group.elements)
        while node := next(it, None):
            match node:
                case RTFControlWord('rtf', version):
                    self.version = version
                case RTFText(_):
                    break

        # Parse contents
        # TODO

        return self
    
    @classmethod
    def parse(cls, s: str) -> Self:
        return cls.parse_from(RTFGroup.parse_from(Reader(s)))
