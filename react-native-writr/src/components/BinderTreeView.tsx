import React, {useState} from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Alert,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {BinderItem, BinderItemType} from '../types';

interface BinderTreeViewProps {
  items: BinderItem[];
  selectedId?: string | null;
  onSelectItem: (itemId: string) => void;
  onAddItem: (parentId?: string) => void;
  onRenameItem: (itemId: string) => void;
  onDeleteItem: (itemId: string) => void;
}

export const BinderTreeView: React.FC<BinderTreeViewProps> = ({
  items,
  selectedId,
  onSelectItem,
  onAddItem,
  onRenameItem,
  onDeleteItem,
}) => {
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set());

  const toggleExpanded = (itemId: string) => {
    const newExpanded = new Set(expandedIds);
    if (newExpanded.has(itemId)) {
      newExpanded.delete(itemId);
    } else {
      newExpanded.add(itemId);
    }
    setExpandedIds(newExpanded);
  };

  const getIconName = (type: BinderItemType, isExpanded: boolean): string => {
    if (type === BinderItemType.FOLDER) {
      return isExpanded ? 'folder-open' : 'folder';
    }
    switch (type) {
      case BinderItemType.TEXT:
        return 'description';
      case BinderItemType.IMAGE:
        return 'image';
      case BinderItemType.PDF:
        return 'picture-as-pdf';
      case BinderItemType.WEB_ARCHIVE:
        return 'web';
      default:
        return 'description';
    }
  };

  const handleLongPress = (item: BinderItem) => {
    Alert.alert('Item Actions', `What do you want to do with "${item.title}"?`, [
      {
        text: 'Add Child',
        onPress: () => onAddItem(item.id),
      },
      {
        text: 'Rename',
        onPress: () => onRenameItem(item.id),
      },
      {
        text: 'Delete',
        onPress: () => {
          Alert.alert(
            'Confirm Delete',
            `Are you sure you want to delete "${item.title}"?`,
            [
              {text: 'Cancel', style: 'cancel'},
              {text: 'Delete', style: 'destructive', onPress: () => onDeleteItem(item.id)},
            ],
          );
        },
        style: 'destructive',
      },
      {text: 'Cancel', style: 'cancel'},
    ]);
  };

  const renderItem = (item: BinderItem, depth: number = 0) => {
    const isExpanded = expandedIds.has(item.id);
    const isSelected = item.id === selectedId;
    const hasChildren = item.children && item.children.length > 0;
    const isFolder = item.type === BinderItemType.FOLDER;

    return (
      <View key={item.id}>
        <TouchableOpacity
          style={[
            styles.item,
            {paddingLeft: 16 + depth * 20},
            isSelected && styles.selectedItem,
          ]}
          onPress={() => onSelectItem(item.id)}
          onLongPress={() => handleLongPress(item)}>
          <View style={styles.itemContent}>
            {isFolder && hasChildren && (
              <TouchableOpacity
                onPress={() => toggleExpanded(item.id)}
                style={styles.expandButton}>
                <Icon
                  name={isExpanded ? 'expand-more' : 'chevron-right'}
                  size={20}
                  color="#666"
                />
              </TouchableOpacity>
            )}
            {(!isFolder || !hasChildren) && <View style={styles.expandButton} />}
            <Icon
              name={getIconName(item.type, isExpanded)}
              size={20}
              color={isFolder ? '#FFA726' : '#42A5F5'}
              style={styles.icon}
            />
            <Text
              style={[
                styles.itemText,
                isSelected && styles.selectedItemText,
              ]}
              numberOfLines={1}>
              {item.title}
            </Text>
          </View>
        </TouchableOpacity>
        {isExpanded &&
          hasChildren &&
          item.children.map((child) => renderItem(child, depth + 1))}
      </View>
    );
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>Binder</Text>
        <TouchableOpacity onPress={() => onAddItem()} style={styles.addButton}>
          <Icon name="add" size={24} color="#fff" />
        </TouchableOpacity>
      </View>
      <ScrollView style={styles.scrollView}>
        {items.map((item) => renderItem(item, 0))}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#6750A4',
    borderBottomWidth: 1,
    borderBottomColor: '#ddd',
  },
  headerText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#fff',
  },
  addButton: {
    padding: 4,
  },
  scrollView: {
    flex: 1,
  },
  item: {
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
    paddingVertical: 12,
    paddingRight: 16,
  },
  selectedItem: {
    backgroundColor: '#E8DEF8',
  },
  itemContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  expandButton: {
    width: 24,
    alignItems: 'center',
  },
  icon: {
    marginRight: 8,
  },
  itemText: {
    fontSize: 14,
    color: '#333',
    flex: 1,
  },
  selectedItemText: {
    fontWeight: '600',
    color: '#1D192B',
  },
});
