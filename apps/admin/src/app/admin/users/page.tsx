'use client';

import { useEffect, useState } from 'react';
import {
  Table,
  TableHeader,
  TableColumn,
  TableBody,
  TableRow,
  TableCell,
  Button,
  Input,
  Card,
  CardBody,
  Modal,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalFooter,
  useDisclosure,
  Chip,
  Pagination,
  Select,
  SelectItem,
} from '@nextui-org/react';
import { apiClient } from '@/services/api';
import { UserStats } from '@/types/admin';
import toast from 'react-hot-toast';

export default function UsersPage() {
  const [users, setUsers] = useState<UserStats[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [total, setTotal] = useState(0);
  const [selectedUser, setSelectedUser] = useState<UserStats | null>(null);
  const { isOpen, onOpen, onOpenChange } = useDisclosure();

  const fetchUsers = async (pageNum: number) => {
    try {
      setLoading(true);
      const offset = (pageNum - 1) * pageSize;
      const response = await apiClient.getUsers(pageSize, offset);
      setUsers(response.data.data);
      setTotal(response.data.total);
    } catch (error) {
      toast.error('Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers(page);
  }, [page, pageSize]);

  const filteredUsers = users.filter(
    (user) =>
      user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.fullName.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleViewDetails = (user: UserStats) => {
    setSelectedUser(user);
    onOpen();
  };

  const handleSuspendUser = async (userId: string) => {
    try {
      await apiClient.updateUser(userId, { status: 'suspended' });
      toast.success('User suspended');
      fetchUsers(page);
    } catch (error) {
      toast.error('Failed to suspend user');
    }
  };

  const handleDeleteUser = async (userId: string) => {
    try {
      await apiClient.deleteUser(userId);
      toast.success('User deleted');
      fetchUsers(page);
    } catch (error) {
      toast.error('Failed to delete user');
    }
  };

  const statusColorMap: Record<string, 'success' | 'warning' | 'danger'> = {
    active: 'success',
    suspended: 'warning',
    deleted: 'danger',
  };

  const tierColorMap: Record<string, 'primary' | 'secondary' | 'success'> = {
    free: 'primary',
    pro: 'secondary',
    enterprise: 'success',
  };

  return (
    <div className="p-8 space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Users</h1>
        <p className="text-gray-600">Manage and monitor user accounts</p>
      </div>

      {/* Search and Filters */}
      <Card>
        <CardBody className="gap-4 p-6">
          <div className="flex gap-4 flex-wrap">
            <Input
              isClearable
              className="w-full md:w-64"
              placeholder="Search by email or name..."
              value={searchTerm}
              onValueChange={setSearchTerm}
              startContent="🔍"
            />
            <Select
              className="w-full md:w-40"
              label="Page Size"
              selectedKeys={[pageSize.toString()]}
              onChange={(e) => {
                setPageSize(parseInt(e.target.value));
                setPage(1);
              }}
            >
              <SelectItem key="10" value="10">
                10 per page
              </SelectItem>
              <SelectItem key="25" value="25">
                25 per page
              </SelectItem>
              <SelectItem key="50" value="50">
                50 per page
              </SelectItem>
            </Select>
          </div>
        </CardBody>
      </Card>

      {/* Users Table */}
      <Card>
        <CardBody className="p-0">
          <Table
            aria-label="Users table"
            isStriped
            isCompact
            removeWrapper
            classNames={{
              table: 'min-h-[400px]',
            }}
          >
            <TableHeader>
              <TableColumn>Email</TableColumn>
              <TableColumn>Name</TableColumn>
              <TableColumn>Tier</TableColumn>
              <TableColumn>Status</TableColumn>
              <TableColumn>Documents</TableColumn>
              <TableColumn>Sessions</TableColumn>
              <TableColumn>Created</TableColumn>
              <TableColumn>Actions</TableColumn>
            </TableHeader>
            <TableBody
              isLoading={loading}
              loadingContent="Loading users..."
              emptyContent="No users found"
            >
              {filteredUsers.map((user) => (
                <TableRow key={user.id}>
                  <TableCell className="text-sm">{user.email}</TableCell>
                  <TableCell className="text-sm">{user.fullName}</TableCell>
                  <TableCell>
                    <Chip
                      size="sm"
                      color={tierColorMap[user.subscriptionTier]}
                      variant="flat"
                    >
                      {user.subscriptionTier}
                    </Chip>
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="sm"
                      color={statusColorMap[user.status]}
                      variant="flat"
                    >
                      {user.status}
                    </Chip>
                  </TableCell>
                  <TableCell className="text-sm">{user.documentsCount}</TableCell>
                  <TableCell className="text-sm">{user.sessionsCount}</TableCell>
                  <TableCell className="text-sm">
                    {new Date(user.createdAt).toLocaleDateString()}
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-2">
                      <Button
                        isIconOnly
                        size="sm"
                        variant="light"
                        onClick={() => handleViewDetails(user)}
                      >
                        👁️
                      </Button>
                      <Button
                        isIconOnly
                        size="sm"
                        variant="light"
                        color="warning"
                        onClick={() => handleSuspendUser(user.id)}
                      >
                        ⛔
                      </Button>
                      <Button
                        isIconOnly
                        size="sm"
                        variant="light"
                        color="danger"
                        onClick={() => handleDeleteUser(user.id)}
                      >
                        🗑️
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardBody>
      </Card>

      {/* Pagination */}
      <div className="flex justify-center">
        <Pagination
          isCompact
          showControls
          showShadow
          color="primary"
          page={page}
          total={Math.ceil(total / pageSize)}
          onChange={setPage}
        />
      </div>

      {/* User Details Modal */}
      <Modal isOpen={isOpen} onOpenChange={onOpenChange} size="2xl">
        <ModalContent>
          {(onClose) => (
            <>
              <ModalHeader className="flex flex-col gap-1">
                User Details
              </ModalHeader>
              <ModalBody>
                {selectedUser && (
                  <div className="space-y-4">
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <p className="text-sm text-gray-600">Email</p>
                        <p className="font-semibold">{selectedUser.email}</p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Name</p>
                        <p className="font-semibold">{selectedUser.fullName}</p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Subscription</p>
                        <Chip
                          color={tierColorMap[selectedUser.subscriptionTier]}
                          variant="flat"
                          className="mt-1"
                        >
                          {selectedUser.subscriptionTier}
                        </Chip>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Status</p>
                        <Chip
                          color={statusColorMap[selectedUser.status]}
                          variant="flat"
                          className="mt-1"
                        >
                          {selectedUser.status}
                        </Chip>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Created</p>
                        <p className="font-semibold">
                          {new Date(selectedUser.createdAt).toLocaleDateString()}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Last Active</p>
                        <p className="font-semibold">
                          {selectedUser.lastActive
                            ? new Date(selectedUser.lastActive).toLocaleDateString()
                            : 'Never'}
                        </p>
                      </div>
                    </div>

                    <div className="border-t pt-4">
                      <h3 className="font-semibold mb-3">Statistics</h3>
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div className="bg-blue-50 p-4 rounded-lg">
                          <p className="text-sm text-gray-600">Documents</p>
                          <p className="text-2xl font-bold text-blue-600">
                            {selectedUser.documentsCount}
                          </p>
                        </div>
                        <div className="bg-green-50 p-4 rounded-lg">
                          <p className="text-sm text-gray-600">Sessions</p>
                          <p className="text-2xl font-bold text-green-600">
                            {selectedUser.sessionsCount}
                          </p>
                        </div>
                        <div className="bg-purple-50 p-4 rounded-lg">
                          <p className="text-sm text-gray-600">Storage Used</p>
                          <p className="text-2xl font-bold text-purple-600">
                            {selectedUser.storageUsedMb}MB
                          </p>
                        </div>
                        <div className="bg-orange-50 p-4 rounded-lg">
                          <p className="text-sm text-gray-600">Storage Limit</p>
                          <p className="text-2xl font-bold text-orange-600">
                            {selectedUser.storageUsedMb}MB
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                )}
              </ModalBody>
              <ModalFooter>
                <Button color="default" onPress={onClose}>
                  Close
                </Button>
              </ModalFooter>
            </>
          )}
        </ModalContent>
      </Modal>
    </div>
  );
}
