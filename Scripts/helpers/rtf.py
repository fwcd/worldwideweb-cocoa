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
    nodes: list['RTFNode'] = field(default_factory=list)

    @classmethod
    def parse_from(cls, r: Reader[str]) -> Self:
        elements = []
        r.expect('{')
        while r.peek() != '}':
            elements.append(RTFNode.parse_from(r))
        r.skip()
        return cls(elements)

    def plain(self) -> str:
        return ''.join(node.plain() for node in self.nodes)

    def __str__(self) -> str:
        return f"{{{''.join(map(str, self.nodes))}}}"

@dataclass
class RTFText:
    value: str

    @classmethod
    def parse_from(cls, r: Reader[str]) -> Self:
        value = ''
        while True:
            if (c := r.peek()) and c not in {'\\', '{', '}'}:
                value += c
                r.skip(len(c))
            elif (nl := r.peek(2)) and nl == '\\\n':
                value += nl[1:]
                r.skip(len(nl))
            else:
                break
        return cls(value)
    
    def plain(self) -> str:
        return self.value

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
    
    def plain(self) -> str:
        match self.value:
            case RTFText() as t: return t.plain()
            case RTFGroup() as g: return g.plain()
            case _: return ''

    def __str__(self) -> str:
        return str(self.value)

# Higher level (structured) parsing

@dataclass
class RTF:
    version: Optional[int] = None
    contents: list[RTFNode] = field(default_factory=list)

    @classmethod
    def parse_from(cls, group: RTFGroup) -> Self:
        self = cls()
        in_header = True

        for node in group.nodes:
            # Parse header node
            if in_header:
                match node.value:
                    case RTFControlWord('rtf', version):
                        self.version = version
                    case RTFText():
                        in_header = False
            
            # Parse content node
            # TODO: Interpret the contents in a higher-level way (e.g. sections/paragraphs)
            if not in_header:
                self.contents.append(node)

        return self
    
    def plain_contents(self) -> str:
        return ''.join(node.plain() for node in self.contents)

    @classmethod
    def parse(cls, s: str) -> Self:
        return cls.parse_from(RTFGroup.parse_from(Reader(s)))
