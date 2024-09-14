from pathlib import Path
from typing import Any, Optional, Self

import xml.etree.ElementTree as ET

next_object_id = 0

class XIBNode:
    '''A wrapper around an XML node that may or may not represent an identified object in a XIB file.'''

    def __init__(self, element: ET.Element, id: Optional[str]=None, custom_class: Optional[str]=None):
        self.element = element
        self.id = id
        self.custom_class = custom_class

        self._connections: Optional[Self] = None
        self._items: Optional[Self] = None
        self._subviews: Optional[Self] = None
        self._cells: Optional[Self] = None
        self._column: Optional[Self] = None
        self._attributes: Optional[Self] = None

    def convert_value(self, v: Any) -> str:
        '''Converts an attribute value to XIB.'''

        if isinstance(v, bool):
            return 'YES' if v else 'NO'
        else:
            return str(v)

    def convert_values(self, d: dict[str, Any]) -> dict[str, str]:
        '''Converts a dict of attributes to XIB.'''

        return {k: self.convert_value(v) for k, v in d.items()}

    def add_object(self, class_or_tag_name: str, id: Optional[str]=None, **kwargs) -> Self:
        '''Adds an object under this node.'''

        assert len(class_or_tag_name) > 0
        is_custom = class_or_tag_name[0].isupper()

        if not id:
            global next_object_id
            id = str(next_object_id)
            next_object_id += 1

        child = ET.Element('customObject' if is_custom else class_or_tag_name, attrib={
            'id': id,
            **self.convert_values(kwargs),
            **({'customClass': class_or_tag_name} if is_custom else {}),
        })
        self.element.append(child)

        return XIBNode(child, id=id, custom_class=class_or_tag_name if is_custom else None)
    
    def add(self, tag_name: str, **kwargs) -> Self:
        '''Adds a custom node under this node.'''

        child = ET.Element(tag_name, attrib={**self.convert_values(kwargs)})
        self.element.append(child)

        return XIBNode(child)
    
    def add_menu_item(self, **kwargs) -> Self:
        '''Adds a menu item to this menu.'''

        items = self if self.element.tag == 'items' else self.items
        return items.add_object('menuItem', **kwargs)

    def add_submenu(self, **kwargs) -> Self:
        '''Adds a submenu to this menu.'''

        assert self.element.tag == 'menuItem', 'Can only add a submenu to a menu item'
        return self.add_object('menu', key='submenu', title=self.element.attrib['title'], **kwargs)
    
    def __str__(self):
        return self.custom_class or self.element.tag

    @property
    def connections(self) -> Self:
        assert self.id is not None, 'Can only connect to an object with an id'
        if self._connections is None:
            self._connections = XIBNode(ET.Element('connections'))
            self.element.append(self._connections.element)
        return self._connections

    @property
    def items(self) -> Self:
        assert self.element.tag == 'menu', 'Can only fetch items on a menu (object)'
        if self._items is None:
            self._items = XIBNode(ET.Element('items'))
            self.element.append(self._items.element)
        return self._items

    @property
    def subviews(self) -> Self:
        if self._subviews is None:
            self._subviews = XIBNode(ET.Element('subviews'))
            self.element.append(self._subviews.element)
        return self._subviews

    @property
    def cells(self) -> Self:
        if self._cells is None:
            self._cells = XIBNode(ET.Element('cells'))
            self.element.append(self._cells.element)
        return self._cells

    @property
    def column(self) -> Self:
        if self._column is None:
            self._column = XIBNode(ET.Element('column'))
            self.element.append(self._column.element)
        return self._column

    @property
    def attributes(self) -> Self:
        if self._attributes is None:
            self._attributes = XIBNode(ET.Element('attributes'))
            self.element.append(self._attributes.element)
        return self._attributes

    def connect_outlet(self, property: str, destination: str | Self):
        '''Adds an outlet to the given destination.'''

        return self.connections.add_object('outlet',
            property=property,
            destination=destination if isinstance(destination, str) else destination.id,
        )
    
    def connect_action(self, selector: str, target: str | Self):
        '''Adds an action invoking the given target with the given selector.'''

        return self.connections.add_object('action',
            selector=selector,
            target=target if isinstance(target, str) else target.id,
        )
    
class XIB:
    '''A high-level wrapper around a XIB/XML tree.'''

    def __init__(self):
        self.root = ET.Element('document', attrib={
            'type': 'com.apple.InterfaceBuilder3.Cocoa.XIB',
            'version': '3.0',
            'toolsVersion': '32700.99.1234',
            'targetRuntime': 'MacOSX.Cocoa',
            'propertyAccessControl': 'none',
            'useAutolayout': 'NO',
            'customObjectInstantiationMethod': 'direct',
        })

        self.tree = ET.ElementTree(self.root)
    
        self.dependencies = self.add_node('dependencies')
        self.dependencies.add('plugIn', identifier='com.apple.InterfaceBuilder.CocoaPlugin', version='22690')
        self.dependencies.add('capability', name='documents saved in the Xcode 8 format', minToolsVersion='8.0')

        self.objects = self.add_node('objects')
        self.resources = self.add_node('resources')

        # Add default objects
        self.files_owner = self.objects.add_object('NSApplication', id='-2', userLabel="File's Owner")
        self.first_responder = self.objects.add_object('FirstResponder', id='-1', userLabel='First Responder')
        self.objects.add_object('NSObject', id='-3', userLabel='Application')
        self.font_manager = self.objects.add_object('NSFontManager')

        # Add main menu
        main_menu = self.objects.add_object('menu', systemMenu='main')
        main_menu.add('point', key='canvasLocation', x=200, y=121)

        app_item = main_menu.add_menu_item(title='WorldWideWeb')
        app_menu = app_item.add_submenu(systemMenu='apple')
        about_item = app_menu.add_menu_item(title='About WorldWideWeb')
        about_item.connect_action('orderFrontStandardAboutPanel:', target=self.first_responder)
        app_menu.add_menu_item(isSeparatorItem=True)

        self.main_menu = main_menu
        self.app_menu = app_menu

    def add_node(self, name: str) -> XIBNode:
        '''Creates a new node under the document root.'''

        element = ET.Element(name)
        self.root.append(element)
        return XIBNode(element)

    def indent(self, indent: str=' ' * 4):
        '''Indents the tree with the given indent (4 spaces by default).'''

        ET.indent(self.tree, space=indent)
    
    def write(self, path: Path):
        '''Writes the XIB to the given path.'''

        self.tree.write(path, encoding='utf-8', xml_declaration=True)
