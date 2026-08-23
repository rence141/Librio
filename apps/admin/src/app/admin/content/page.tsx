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
import { Material } from '@/types/admin';
import toast from 'react-hot-toast';

export default function ContentPage() {
  const [content, setContent] = useState<Material[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [total, setTotal] = useState(0);
  const [selectedContent, setSelectedContent] = useState<Material | null>(null);
  const { isOpen, onOpen, onOpenChange } = useDisclosure();

  const fetchContent = async (pageNum: number) => {
    try {
      setLoading(true);
      const offset = (pageNum - 1) * pageSize;
      const response = await apiClient.getContent(pageSize, offset);
      setContent(response.data.data);
      setTotal(response.data.total);
    } catch (error) {
      toast.error('Failed to load content');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchContent(page);
  }, [page, pageSize]);

  const filteredContent = content.filter(
    (item) =>
      item.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.subject.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleViewDetails = (item: Material) => {
    setSelectedContent(item);
    onOpen();
  };

  const handleApprove = async (contentId: string) => {
    try {
      await apiClient.updateContent(contentId, { status: 'approved' });
      toast.success('Content approved');
      fetchContent(page);
    } catch (error) {
      toast.error('Failed to approve content');
    }
  };

  const handleReject = async (contentId: string) => {
    try {
      await apiClient.updateContent(contentId, { status: 'rejected' });
      toast.success('Content rejected');
      fetchContent(page);
    } catch (error) {
      toast.error('Failed to reject content');
    }
  };

  const handleFeature = async (contentId: string) => {
    try {
      await apiClient.updateContent(contentId, { isFeatured: true });
      toast.success('Content featured');
      fetchContent(page);
    } catch (error) {
      toast.error('Failed to feature content');
    }
  };

  const handleDelete = async (contentId: string) => {
    try {
      await apiClient.deleteContent(contentId);
      toast.success('Content deleted');
      fetchContent(page);
    } catch (error) {
      toast.error('Failed to delete content');
    }
  };

  const statusColorMap: Record<string, 'success' | 'warning' | 'danger'> = {
    pending: 'warning',
    approved: 'success',
    rejected: 'danger',
  };

  return (
    <div className="p-8 space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Content Management</h1>
        <p className="text-gray-600">Review and moderate user-generated content</p>
      </div>

      {/* Search and Filters */}
      <Card>
        <CardBody className="gap-4 p-6">
          <div className="flex gap-4 flex-wrap">
            <Input
              isClearable
              className="w-full md:w-64"
              placeholder="Search by title or subject..."
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

      {/* Content Table */}
      <Card>
        <CardBody className="p-0">
          <Table
            aria-label="Content table"
            isStriped
            isCompact
            removeWrapper
            classNames={{
              table: 'min-h-[400px]',
            }}
          >
            <TableHeader>
              <TableColumn>Title</TableColumn>
              <TableColumn>Subject</TableColumn>
              <TableColumn>Status</TableColumn>
              <TableColumn>Downloads</TableColumn>
              <TableColumn>Rating</TableColumn>
              <TableColumn>Featured</TableColumn>
              <TableColumn>Created</TableColumn>
              <TableColumn>Actions</TableColumn>
            </TableHeader>
            <TableBody
              isLoading={loading}
              loadingContent="Loading content..."
              emptyContent="No content found"
            >
              {filteredContent.map((item) => (
                <TableRow key={item.id}>
                  <TableCell className="text-sm font-medium">{item.title}</TableCell>
                  <TableCell className="text-sm">{item.subject}</TableCell>
                  <TableCell>
                    <Chip
                      size="sm"
                      color={statusColorMap[item.status]}
                      variant="flat"
                    >
                      {item.status}
                    </Chip>
                  </TableCell>
                  <TableCell className="text-sm">{item.downloadCount}</TableCell>
                  <TableCell className="text-sm">
                    {item.rating ? `${item.rating.toFixed(1)}⭐` : 'N/A'}
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="sm"
                      color={item.isFeatured ? 'success' : 'default'}
                      variant="flat"
                    >
                      {item.isFeatured ? '✓ Featured' : 'Not Featured'}
                    </Chip>
                  </TableCell>
                  <TableCell className="text-sm">
                    {new Date(item.createdAt).toLocaleDateString()}
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-2">
                      <Button
                        isIconOnly
                        size="sm"
                        variant="light"
                        onClick={() => handleViewDetails(item)}
                      >
                        👁️
                      </Button>
                      {item.status === 'pending' && (
                        <>
                          <Button
                            isIconOnly
                            size="sm"
                            variant="light"
                            color="success"
                            onClick={() => handleApprove(item.id)}
                          >
                            ✓
                          </Button>
                          <Button
                            isIconOnly
                            size="sm"
                            variant="light"
                            color="danger"
                            onClick={() => handleReject(item.id)}
                          >
                            ✕
                          </Button>
                        </>
                      )}
                      {item.status === 'approved' && !item.isFeatured && (
                        <Button
                          isIconOnly
                          size="sm"
                          variant="light"
                          color="warning"
                          onClick={() => handleFeature(item.id)}
                        >
                          ⭐
                        </Button>
                      )}
                      <Button
                        isIconOnly
                        size="sm"
                        variant="light"
                        color="danger"
                        onClick={() => handleDelete(item.id)}
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

      {/* Content Details Modal */}
      <Modal isOpen={isOpen} onOpenChange={onOpenChange} size="2xl">
        <ModalContent>
          {(onClose) => (
            <>
              <ModalHeader className="flex flex-col gap-1">
                Content Details
              </ModalHeader>
              <ModalBody>
                {selectedContent && (
                  <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-sm text-gray-600">Title</p>
                        <p className="font-semibold">{selectedContent.title}</p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Subject</p>
                        <p className="font-semibold">{selectedContent.subject}</p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Topic</p>
                        <p className="font-semibold">{selectedContent.topic || 'N/A'}</p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Status</p>
                        <Chip
                          color={statusColorMap[selectedContent.status]}
                          variant="flat"
                          className="mt-1"
                        >
                          {selectedContent.status}
                        </Chip>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Created By</p>
                        <p className="font-semibold">{selectedContent.createdBy}</p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Created</p>
                        <p className="font-semibold">
                          {new Date(selectedContent.createdAt).toLocaleDateString()}
                        </p>
                      </div>
                    </div>

                    <div className="border-t pt-4">
                      <h3 className="font-semibold mb-3">Statistics</h3>
                      <div className="grid grid-cols-2 gap-4">
                        <div className="bg-blue-50 p-4 rounded-lg">
                          <p className="text-sm text-gray-600">Downloads</p>
                          <p className="text-2xl font-bold text-blue-600">
                            {selectedContent.downloadCount}
                          </p>
                        </div>
                        <div className="bg-yellow-50 p-4 rounded-lg">
                          <p className="text-sm text-gray-600">Rating</p>
                          <p className="text-2xl font-bold text-yellow-600">
                            {selectedContent.rating ? selectedContent.rating.toFixed(1) : 'N/A'}
                          </p>
                        </div>
                        <div className="bg-green-50 p-4 rounded-lg">
                          <p className="text-sm text-gray-600">Public</p>
                          <p className="text-2xl font-bold text-green-600">
                            {selectedContent.isPublic ? 'Yes' : 'No'}
                          </p>
                        </div>
                        <div className="bg-purple-50 p-4 rounded-lg">
                          <p className="text-sm text-gray-600">Featured</p>
                          <p className="text-2xl font-bold text-purple-600">
                            {selectedContent.isFeatured ? 'Yes' : 'No'}
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
