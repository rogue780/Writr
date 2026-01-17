import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  TextInput,
  Modal,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import { useAppDispatch, useAppSelector } from '../redux/hooks';
import { loadRecentProjects, removeRecentProject, clearRecentProjects, addRecentProject } from '../redux/slices/recentProjectsSlice';
import { setProject, clearProject } from '../redux/slices/projectSlice';
import { ScrivenerService } from '../services/ScrivenerService';
import { StorageService } from '../services/StorageService';
import { RecentProjectsService } from '../services/RecentProjectsService';
import { CloudStorageService } from '../services/CloudStorageService';
import { CloudSyncService } from '../services/CloudSyncService';
import { CloudProviderType, RecentProject, CloudFile } from '../types';

interface HomeScreenProps {
  navigation: any;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ navigation }) => {
  const dispatch = useAppDispatch();
  const currentProject = useAppSelector((state) => state.project.currentProject);
  const recentProjects = useAppSelector((state) => state.recentProjects.projects);
  const isLoading = useAppSelector((state) => state.recentProjects.loading);

  const [showOpenOptions, setShowOpenOptions] = useState(false);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [newProjectName, setNewProjectName] = useState('');
  const [loading, setLoading] = useState(false);

  const scrivenerService = ScrivenerService.getInstance();
  const storageService = StorageService.getInstance();
  const recentProjectsService = RecentProjectsService.getInstance();
  const cloudStorageService = CloudStorageService.getInstance();
  const cloudSyncService = CloudSyncService.getInstance();

  useEffect(() => {
    dispatch(loadRecentProjects());
  }, [dispatch]);

  const handleOpenProject = () => {
    setShowOpenOptions(true);
  };

  const handleOpenOptionSelect = async (option: string) => {
    setShowOpenOptions(false);

    switch (option) {
      case 'file_picker':
        await openExistingProject();
        break;
      case 'google_drive':
        await openCloudProject(CloudProviderType.GOOGLE_DRIVE);
        break;
      case 'dropbox':
        await openCloudProject(CloudProviderType.DROPBOX);
        break;
      case 'onedrive':
        await openCloudProject(CloudProviderType.ONEDRIVE);
        break;
    }
  };

  const openExistingProject = async () => {
    setLoading(true);

    try {
      const projectPath = await storageService.pickScrivenerProject();

      if (!projectPath) {
        setLoading(false);
        return;
      }

      const cachedPath = await storageService.copyProjectToCache(projectPath);
      const pathToLoad = cachedPath || projectPath;

      const project = await scrivenerService.loadProject(pathToLoad);

      if (!project) {
        setLoading(false);
        Alert.alert('Error', scrivenerService.getError() || 'Failed to load project');
        return;
      }

      dispatch(setProject(project));
      await dispatch(addRecentProject({ name: project.name, path: pathToLoad }));

      setLoading(false);
      navigation.navigate('ProjectEditor');
    } catch (error) {
      setLoading(false);
      Alert.alert('Error', `Error opening project: ${error}`);
    }
  };

  const openCloudProject = async (provider: CloudProviderType) => {
    setLoading(true);

    try {
      const success = await cloudStorageService.selectProvider(provider);

      if (!success) {
        setLoading(false);
        Alert.alert('Error', `Failed to sign in to ${provider}`);
        return;
      }

      setLoading(false);

      navigation.navigate('CloudBrowser', {
        onProjectSelect: async (selectedProject: CloudFile) => {
          setLoading(true);

          try {
            const localPath = await cloudSyncService.downloadProject(selectedProject);

            if (!localPath) {
              setLoading(false);
              Alert.alert('Error', cloudSyncService.getError() || 'Failed to download project');
              return;
            }

            const project = await scrivenerService.loadProject(localPath);

            if (!project) {
              setLoading(false);
              Alert.alert('Error', scrivenerService.getError() || 'Failed to load project');
              return;
            }

            dispatch(setProject(project));
            await dispatch(addRecentProject({ name: project.name, path: localPath }));

            setLoading(false);
            navigation.navigate('ProjectEditor');
            Alert.alert('Success', `Project downloaded from ${provider}`);
          } catch (error) {
            setLoading(false);
            Alert.alert('Error', `${error}`);
          }
        },
      });
    } catch (error) {
      setLoading(false);
      Alert.alert('Error', `${error}`);
    }
  };

  const handleCreateProject = () => {
    setShowCreateDialog(true);
  };

  const confirmCreateProject = async () => {
    if (!newProjectName.trim()) {
      return;
    }

    setShowCreateDialog(false);
    setLoading(true);

    try {
      const directory = await storageService.pickDirectoryForNewProject();

      if (!directory) {
        setLoading(false);
        setNewProjectName('');
        return;
      }

      const project = await scrivenerService.createProject(newProjectName, directory);

      if (!project) {
        setLoading(false);
        setNewProjectName('');
        Alert.alert('Error', scrivenerService.getError() || 'Failed to create project');
        return;
      }

      dispatch(setProject(project));
      await dispatch(addRecentProject({ name: project.name, path: project.path }));

      setLoading(false);
      setNewProjectName('');
      navigation.navigate('ProjectEditor');
    } catch (error) {
      setLoading(false);
      setNewProjectName('');
      Alert.alert('Error', `Error creating project: ${error}`);
    }
  };

  const handleOpenRecentProject = async (project: RecentProject) => {
    setLoading(true);

    try {
      const loadedProject = await scrivenerService.loadProject(project.path);

      if (!loadedProject) {
        setLoading(false);
        Alert.alert('Error', scrivenerService.getError() || 'Failed to load project');
        return;
      }

      dispatch(setProject(loadedProject));
      await dispatch(addRecentProject({ name: loadedProject.name, path: project.path }));

      setLoading(false);
      navigation.navigate('ProjectEditor');
    } catch (error) {
      setLoading(false);
      Alert.alert('Error', `Error opening project: ${error}`);
    }
  };

  const handleRemoveRecentProject = (path: string) => {
    dispatch(removeRecentProject(path));
  };

  const handleClearRecentProjects = () => {
    Alert.alert(
      'Clear Recent Projects',
      'Are you sure you want to clear all recent projects?\n\nThis will not delete the actual project files.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear All',
          style: 'destructive',
          onPress: () => dispatch(clearRecentProjects()),
        },
      ]
    );
  };

  const handleOpenCurrentProject = () => {
    navigation.navigate('ProjectEditor');
  };

  const formatRelativeTime = (timestamp: number): string => {
    const now = Date.now();
    const diff = now - timestamp;
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return new Date(timestamp).toLocaleDateString();
  };

  return (
    <View style={styles.container}>
      <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent}>
        <Text style={styles.title}>Welcome to Writr</Text>
        <Text style={styles.subtitle}>A Scrivener-compatible editor</Text>

        {/* Info Card */}
        <View style={styles.infoCard}>
          <View style={styles.infoHeader}>
            <Icon name="info-outline" size={24} color="#1565C0" />
            <Text style={styles.infoTitle}>Access Files Anywhere</Text>
          </View>
          <Text style={styles.infoText}>
            Writr provides two ways to access your projects:{'\n\n'}
            1. Native File Picker (recommended):{'\n'}
            • Local storage, network drives, external drives{'\n'}
            • Works with installed cloud apps{'\n'}
            • No setup required{'\n\n'}
            2. Direct Cloud API Access:{'\n'}
            • Google Drive, Dropbox, OneDrive{'\n'}
            • Requires API configuration{'\n'}
            • Browse and manage cloud files
          </Text>
        </View>

        {/* Open Project Button */}
        <TouchableOpacity
          style={styles.primaryButton}
          onPress={handleOpenProject}
          disabled={loading}
        >
          <Icon name="folder-open" size={28} color="#FFFFFF" />
          <Text style={styles.primaryButtonText}>Open Project</Text>
        </TouchableOpacity>

        {/* Create New Project Button */}
        <TouchableOpacity
          style={styles.secondaryButton}
          onPress={handleCreateProject}
          disabled={loading}
        >
          <Icon name="add-circle-outline" size={28} color="#673AB7" />
          <Text style={styles.secondaryButtonText}>Create New Project</Text>
        </TouchableOpacity>

        {/* Currently Open Project */}
        {currentProject && (
          <TouchableOpacity style={styles.currentProjectCard} onPress={handleOpenCurrentProject}>
            <Icon name="book" size={32} color="#673AB7" />
            <View style={styles.currentProjectInfo}>
              <Text style={styles.currentProjectName}>{currentProject.name}</Text>
              <Text style={styles.currentProjectSubtitle}>Currently open</Text>
            </View>
            <Icon name="arrow-forward" size={24} color="#666" />
          </TouchableOpacity>
        )}

        {/* Recent Projects Section */}
        {!isLoading && recentProjects.length > 0 && (
          <View style={styles.recentSection}>
            <View style={styles.recentHeader}>
              <Text style={styles.recentTitle}>Recent Projects</Text>
              <TouchableOpacity onPress={handleClearRecentProjects}>
                <View style={styles.clearButton}>
                  <Icon name="clear-all" size={18} color="#673AB7" />
                  <Text style={styles.clearButtonText}>Clear</Text>
                </View>
              </TouchableOpacity>
            </View>

            {recentProjects.map((project) => (
              <TouchableOpacity
                key={project.path}
                style={styles.recentProjectCard}
                onPress={() => handleOpenRecentProject(project)}
              >
                <View style={styles.recentProjectIcon}>
                  <Icon name="book" size={24} color="#673AB7" />
                </View>
                <View style={styles.recentProjectInfo}>
                  <Text style={styles.recentProjectName}>{project.name}</Text>
                  <Text style={styles.recentProjectPath} numberOfLines={1}>
                    {project.path}
                  </Text>
                  <Text style={styles.recentProjectTime}>
                    {formatRelativeTime(project.lastOpened)}
                  </Text>
                </View>
                <TouchableOpacity
                  onPress={() => handleRemoveRecentProject(project.path)}
                  hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                >
                  <Icon name="close" size={20} color="#999" />
                </TouchableOpacity>
              </TouchableOpacity>
            ))}
          </View>
        )}

        {isLoading && (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color="#673AB7" />
          </View>
        )}
      </ScrollView>

      {/* Loading Overlay */}
      {loading && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color="#FFFFFF" />
        </View>
      )}

      {/* Open Project Options Modal */}
      <Modal
        visible={showOpenOptions}
        transparent
        animationType="fade"
        onRequestClose={() => setShowOpenOptions(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Open Project</Text>

            <TouchableOpacity
              style={styles.modalOption}
              onPress={() => handleOpenOptionSelect('file_picker')}
            >
              <Icon name="folder" size={24} color="#2196F3" />
              <View style={styles.modalOptionText}>
                <Text style={styles.modalOptionTitle}>File Picker</Text>
                <Text style={styles.modalOptionSubtitle}>Use native file picker (recommended)</Text>
              </View>
            </TouchableOpacity>

            <View style={styles.modalDivider} />

            <TouchableOpacity
              style={styles.modalOption}
              onPress={() => handleOpenOptionSelect('google_drive')}
            >
              <Icon name="cloud" size={24} color="#4CAF50" />
              <View style={styles.modalOptionText}>
                <Text style={styles.modalOptionTitle}>Google Drive</Text>
                <Text style={styles.modalOptionSubtitle}>Browse with Google Drive API</Text>
              </View>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.modalOption}
              onPress={() => handleOpenOptionSelect('dropbox')}
            >
              <Icon name="cloud" size={24} color="#2196F3" />
              <View style={styles.modalOptionText}>
                <Text style={styles.modalOptionTitle}>Dropbox</Text>
                <Text style={styles.modalOptionSubtitle}>Browse with Dropbox API</Text>
              </View>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.modalOption}
              onPress={() => handleOpenOptionSelect('onedrive')}
            >
              <Icon name="cloud" size={24} color="#9C27B0" />
              <View style={styles.modalOptionText}>
                <Text style={styles.modalOptionTitle}>OneDrive</Text>
                <Text style={styles.modalOptionSubtitle}>Browse with OneDrive API</Text>
              </View>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.modalCancelButton}
              onPress={() => setShowOpenOptions(false)}
            >
              <Text style={styles.modalCancelText}>Cancel</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Create Project Dialog */}
      <Modal
        visible={showCreateDialog}
        transparent
        animationType="fade"
        onRequestClose={() => setShowCreateDialog(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.dialogContent}>
            <Text style={styles.dialogTitle}>Create New Project</Text>
            <TextInput
              style={styles.dialogInput}
              placeholder="Project Name"
              placeholderTextColor="#999"
              value={newProjectName}
              onChangeText={setNewProjectName}
              autoFocus
            />
            <View style={styles.dialogButtons}>
              <TouchableOpacity
                style={styles.dialogButton}
                onPress={() => {
                  setShowCreateDialog(false);
                  setNewProjectName('');
                }}
              >
                <Text style={styles.dialogButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.dialogButton, styles.dialogButtonPrimary]}
                onPress={confirmCreateProject}
              >
                <Text style={[styles.dialogButtonText, styles.dialogButtonTextPrimary]}>
                  Create
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginTop: 16,
  },
  subtitle: {
    fontSize: 16,
    color: '#757575',
    textAlign: 'center',
    marginTop: 8,
    marginBottom: 48,
  },
  infoCard: {
    backgroundColor: '#E3F2FD',
    borderRadius: 12,
    padding: 16,
    marginBottom: 32,
  },
  infoHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  infoTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#0D47A1',
    marginLeft: 8,
  },
  infoText: {
    fontSize: 14,
    color: '#0D47A1',
    lineHeight: 21,
  },
  primaryButton: {
    backgroundColor: '#673AB7',
    borderRadius: 12,
    padding: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  primaryButtonText: {
    fontSize: 18,
    color: '#FFFFFF',
    fontWeight: '600',
    marginLeft: 12,
  },
  secondaryButton: {
    borderWidth: 2,
    borderColor: '#673AB7',
    borderRadius: 12,
    padding: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 32,
  },
  secondaryButtonText: {
    fontSize: 18,
    color: '#673AB7',
    fontWeight: '600',
    marginLeft: 12,
  },
  currentProjectCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 32,
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  currentProjectInfo: {
    flex: 1,
    marginLeft: 16,
  },
  currentProjectName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#000',
  },
  currentProjectSubtitle: {
    fontSize: 14,
    color: '#757575',
    marginTop: 4,
  },
  recentSection: {
    marginTop: 16,
  },
  recentHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  recentTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#000',
  },
  clearButton: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  clearButtonText: {
    fontSize: 14,
    color: '#673AB7',
    marginLeft: 4,
  },
  recentProjectCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
  },
  recentProjectIcon: {
    width: 48,
    height: 48,
    borderRadius: 8,
    backgroundColor: 'rgba(103, 58, 183, 0.1)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  recentProjectInfo: {
    flex: 1,
    marginLeft: 12,
  },
  recentProjectName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
  },
  recentProjectPath: {
    fontSize: 12,
    color: '#757575',
    marginTop: 4,
  },
  recentProjectTime: {
    fontSize: 11,
    color: '#9E9E9E',
    marginTop: 2,
  },
  loadingContainer: {
    padding: 32,
    alignItems: 'center',
  },
  loadingOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  modalContent: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    width: '100%',
    maxWidth: 400,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 16,
    textAlign: 'center',
  },
  modalOption: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
  },
  modalOptionText: {
    flex: 1,
    marginLeft: 16,
  },
  modalOptionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
  },
  modalOptionSubtitle: {
    fontSize: 14,
    color: '#757575',
    marginTop: 2,
  },
  modalDivider: {
    height: 1,
    backgroundColor: '#E0E0E0',
    marginVertical: 8,
  },
  modalCancelButton: {
    marginTop: 16,
    padding: 12,
    alignItems: 'center',
  },
  modalCancelText: {
    fontSize: 16,
    color: '#673AB7',
    fontWeight: '600',
  },
  dialogContent: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 24,
    width: '100%',
    maxWidth: 400,
  },
  dialogTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  dialogInput: {
    borderWidth: 1,
    borderColor: '#E0E0E0',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 24,
  },
  dialogButtons: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  dialogButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    marginLeft: 8,
  },
  dialogButtonPrimary: {
    backgroundColor: '#673AB7',
    borderRadius: 8,
  },
  dialogButtonText: {
    fontSize: 16,
    color: '#673AB7',
    fontWeight: '600',
  },
  dialogButtonTextPrimary: {
    color: '#FFFFFF',
  },
});
