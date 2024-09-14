from typing import Generic, Self, TypeVar

class ReaderError(Exception):
    pass

T = TypeVar('T')

class Reader(Generic[T]):
    def __init__(self, raw_str: T, i: int = 0):
        self.raw = raw_str
        self.i = i
    
    def child(self) -> Self:
        return Reader(self.raw, self.i)

    def peek(self, n: int = 1) -> T:
        if self.i + n > len(self.raw):
            raise ReaderError(f'String ended too early, could not read next {n} char(s)')

        return self.raw[self.i:self.i + n]

    def skip(self, n: int = 1):
        self.i += n

    def next(self, n: int = 1) -> T:
        s = self.peek(n)
        self.skip(n)
        return s

    def expect(self, expected: T):
        s = self.next(len(expected))
        if s != expected:
            raise ReaderError(f"Expected '{expected}', but got '{s}'")
    
    def next_word(self) -> str:
        assert isinstance(self.raw, str), 'read_word is only implemented for string readers'

        w = ''
        while (c := self.peek()) and c.isalpha():
            w += c
            self.skip()
        return w

    def next_int(self) -> int:
        assert isinstance(self.raw, str), 'read_int is only implemented for string readers'

        d = ''
        if (c := self.peek()) and c == '-':
            d += c
            self.skip()
        while (c := self.peek()) and c.isnumeric():
            d += c
            self.skip()
        return int(d)
