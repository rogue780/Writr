import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {BinderItem, BinderItemType} from '../types';

interface DocumentEditorProps {
  item: BinderItem | null;
  content: string;
  onContentChange: (content: string) => void;
  hasUnsavedChanges: boolean;
}

export const DocumentEditor: React.FC<DocumentEditorProps> = ({
  item,
  content,
  onContentChange,
  hasUnsavedChanges,
}) => {
  const [localContent, setLocalContent] = useState(content);
  const [wordCount, setWordCount] = useState(0);
  const [charCount, setCharCount] = useState(0);

  useEffect(() => {
    setLocalContent(content);
    updateCounts(content);
  }, [content]);

  const updateCounts = (text: string) => {
    setCharCount(text.length);
    const words = text.trim().split(/\s+/).filter((word) => word.length > 0);
    setWordCount(words.length);
  };

  const handleTextChange = (text: string) => {
    setLocalContent(text);
    updateCounts(text);
    onContentChange(text);
  };

  const getIconName = (type: BinderItemType): string => {
    switch (type) {
      case BinderItemType.FOLDER:
        return 'folder';
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

  if (!item) {
    return (
      <View style={styles.emptyContainer}>
        <Icon name="edit" size={64} color="#ccc" />
        <Text style={styles.emptyText}>Select a document to edit</Text>
      </View>
    );
  }

  if (item.type !== BinderItemType.TEXT && item.type !== BinderItemType.FOLDER) {
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <View style={styles.titleRow}>
            <Icon
              name={getIconName(item.type)}
              size={20}
              color="#666"
              style={styles.icon}
            />
            <Text style={styles.title}>{item.title}</Text>
          </View>
        </View>
        <View style={styles.emptyContainer}>
          <Icon name={getIconName(item.type)} size={64} color="#ccc" />
          <Text style={styles.emptyText}>
            This type of document cannot be edited
          </Text>
        </View>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
      <View style={styles.header}>
        <View style={styles.titleRow}>
          <Icon
            name={getIconName(item.type)}
            size={20}
            color="#666"
            style={styles.icon}
          />
          <Text style={styles.title}>{item.title}</Text>
          {hasUnsavedChanges && (
            <View style={styles.unsavedIndicator}>
              <Icon name="circle" size={8} color="#FF9800" />
            </View>
          )}
        </View>
      </View>
      <TextInput
        style={styles.editor}
        multiline
        value={localContent}
        onChangeText={handleTextChange}
        placeholder="Start writing..."
        placeholderTextColor="#999"
        textAlignVertical="top"
      />
      <View style={styles.footer}>
        <Text style={styles.footerText}>
          Words: {wordCount} | Characters: {charCount}
        </Text>
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#fafafa',
  },
  emptyText: {
    marginTop: 16,
    fontSize: 16,
    color: '#999',
  },
  header: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
    backgroundColor: '#fff',
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  icon: {
    marginRight: 8,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    flex: 1,
  },
  unsavedIndicator: {
    marginLeft: 8,
  },
  editor: {
    flex: 1,
    padding: 16,
    fontSize: 16,
    lineHeight: 24,
    color: '#333',
  },
  footer: {
    padding: 12,
    borderTopWidth: 1,
    borderTopColor: '#eee',
    backgroundColor: '#f9f9f9',
  },
  footerText: {
    fontSize: 12,
    color: '#666',
  },
});
