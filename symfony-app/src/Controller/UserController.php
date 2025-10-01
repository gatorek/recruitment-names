<?php

namespace App\Controller;

use App\Exception\InvalidUserIdException;
use App\Service\PhoenixApiService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class UserController extends AbstractController
{
    public function __construct(
        private PhoenixApiService $phoenixApiService
    ) {
    }

    #[Route('/users/{id}', name: 'user_show', methods: ['GET'])]
    public function show(string $id): Response
    {
        try {
            $userId = $this->validateAndParseUserId($id);
            $user = $this->phoenixApiService->getUser($userId);
            
            return $this->render('user/show.html.twig', [
                'user' => $user
            ]);
            
        } catch (InvalidUserIdException $e) {
            return $this->render('user/error.html.twig', [
                'error' => $e->getMessage()
            ]);
        } catch (\Exception $e) {
            $this->addFlash('error', 'Failed to fetch user data: ' . $e->getMessage());
            
            return $this->render('user/error.html.twig', [
                'error' => $e->getMessage()
            ]);
        }
    }

    #[Route('/users', name: 'user_list', methods: ['GET'])]
    public function list(Request $request): Response
    {
        try {
            $sortField = $this->getSortField($request);
            $sortOrder = $this->getSortOrder($request);
            $filters = [];
            
            if ($sortOrder && $sortField) {
                $filters['sort'] = $sortField;
                $filters['order'] = $sortOrder;
            }
            
            $users = $this->phoenixApiService->listUsers($filters);
            
            return $this->render('user/list.html.twig', [
                'users' => $users,
                'currentSort' => $sortOrder,
                'currentSortField' => $sortField
            ]);
            
        } catch (\InvalidArgumentException $e) {
            $this->addFlash('error', 'Invalid sorting parameter: ' . $e->getMessage());
            
            return $this->render('user/list.html.twig', [
                'users' => [],
                'currentSort' => null,
                'currentSortField' => null,
                'error' => $e->getMessage()
            ]);
        } catch (\Exception $e) {
            $this->addFlash('error', 'Failed to fetch users list: ' . $e->getMessage());
            
            return $this->render('user/list.html.twig', [
                'users' => [],
                'currentSort' => null,
                'currentSortField' => 'first_name',
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Validates and parses the user ID parameter
     *
     * @param string $id The ID parameter from the URL
     * @return int The validated and parsed user ID
     * @throws InvalidUserIdException When the ID is invalid
     */
    private function validateAndParseUserId(string $id): int
    {
        // Check if the ID is numeric
        if (!is_numeric($id)) {
            throw new InvalidUserIdException($id);
        }
        
        $userId = (int)$id;
        
        // Check if the ID is positive
        if ($userId <= 0) {
            throw new InvalidUserIdException($id);
        }
        
        return $userId;
    }

    /**
     * Validates and retrieves the sort field parameter
     *
     * @param Request $request The HTTP request
     * @return string|null The validated sort field or null if not provided
     * @throws \InvalidArgumentException If sort_field has invalid value
     */
    private function getSortField(Request $request): ?string
    {
        $sortField = $request->query->get('sort_field');
        
        // If null or empty string, return null
        if ($sortField === null || $sortField === '') {
            return null;
        }
        
        // Check if it's a valid sort field
        $validSortFields = ['first_name', 'last_name', 'gender', 'birthdate'];
        
        if (!in_array($sortField, $validSortFields, true)) {
            throw new \InvalidArgumentException("Invalid sort field: {$sortField}");
        }
        
        return $sortField;
    }

    /**
     * Determines the sort order based on current query parameters
     * Implements cyclic sorting: asc -> desc -> default (null)
     *
     * @param Request $request The HTTP request
     * @return string|null The sort order ('asc', 'desc', or null for default)
     * @throws \InvalidArgumentException If sort_order has invalid value
     */
    private function getSortOrder(Request $request): ?string
    {
        $currentSort = $request->query->get('sort_order');
                
        switch ($currentSort) {
            case 'asc':
                return 'asc'; // Currently ascending
            case 'desc':
                return 'desc'; // Currently descending
            case '':
            case null:
                return null;
            default:
                throw new \InvalidArgumentException("Invalid sort order: {$currentSort}");
        }
    }

}
