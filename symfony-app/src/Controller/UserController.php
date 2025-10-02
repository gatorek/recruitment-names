<?php

namespace App\Controller;

use App\DTO\UserDTO;
use App\Exception\InvalidUserIdException;
use App\Form\UserCreateType;
use App\Form\UserEditType;
use App\Service\PhoenixApiService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class UserController extends AbstractController
{
    public function __construct(
        private PhoenixApiService $phoenixApiService
    ) {
    }

    #[Route('/users/create', name: 'user_create', methods: ['GET'])]
    public function create(Request $request): Response
    {
        $form = $this->createForm(UserCreateType::class);
        
        return $this->render('user/create.html.twig', [
            'form' => $form->createView()
        ]);
    }

    #[Route('/users/create', name: 'user_store', methods: ['POST'])]
    public function store(Request $request): Response
    {
        $form = $this->createForm(UserCreateType::class);
        $form->handleRequest($request);
        
        if ($form->isSubmitted() && $form->isValid()) {
            try {
                // Create UserDTO from form data (without ID for creation)
                $userDTO = new UserDTO(
                    id: 0, // Temporary ID, will be ignored by API
                    firstName: $form->get('firstName')->getData(),
                    lastName: $form->get('lastName')->getData(),
                    gender: $form->get('gender')->getData(),
                    birthdate: $form->get('birthdate')->getData()
                );
                
                // Call Phoenix API to create user
                $createdUser = $this->phoenixApiService->create($userDTO);
                
                $this->addFlash('success', 'User has been created successfully');
                return $this->redirectToRoute('user_show', ['id' => $createdUser->id]);
                
            } catch (\Exception $e) {
                $this->addFlash('error', 'Failed to create user: ' . $e->getMessage());
                // Continue to render the form with error
            }
        }
        
        // Check if form has validation errors
        if ($form->isSubmitted() && !$form->isValid()) {
            $this->addFlash('error', 'Please correct the errors below.');
        }
        
        // Always render the form with current data and validation errors
        return $this->render('user/create.html.twig', [
            'form' => $form->createView()
        ]);
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
            $this->addFlash('error', $e->getMessage());
            return $this->redirectToRoute('user_list');
        } catch (\Exception $e) {
            $this->addFlash('error', 'Failed to fetch user data: ' . $e->getMessage());
            return $this->redirectToRoute('user_list');
        }
    }

    #[Route('/users/{id}/edit', name: 'user_edit', methods: ['GET'])]
    public function edit(string $id, Request $request): Response
    {
        try {
            $userId = $this->validateAndParseUserId($id);
            
            // Always fetch fresh user data from API
            $user = $this->phoenixApiService->getUser($userId);
            
            $form = $this->createForm(UserEditType::class, $user);
            
            // Set default values for unmapped fields with fresh data from API
            $form->get('firstName')->setData($user->firstName);
            $form->get('lastName')->setData($user->lastName);
            $form->get('gender')->setData($user->gender);
            $form->get('birthdate')->setData($user->birthdate);
            
            return $this->render('user/edit.html.twig', [
                'user' => $user,
                'form' => $form->createView()
            ]);
            
        } catch (InvalidUserIdException $e) {
            $this->addFlash('error', $e->getMessage());
            return $this->redirectToRoute('user_list');
        } catch (\Exception $e) {
            $this->addFlash('error', 'Failed to fetch user data: ' . $e->getMessage());
            return $this->redirectToRoute('user_list');
        }
    }

    #[Route('/users/{id}/edit', name: 'user_update', methods: ['POST'])]
    public function update(string $id, Request $request): Response
    {
        try {
            $userId = $this->validateAndParseUserId($id);
            
            // Create form without binding to user data
            // We'll use the data submitted by the user
            $form = $this->createForm(UserEditType::class);
            $form->handleRequest($request);
            
            // Get user data from form for display purposes
            $userData = [
                'id' => $userId,
                'firstName' => $form->get('firstName')->getData(),
                'lastName' => $form->get('lastName')->getData(),
                'gender' => $form->get('gender')->getData(),
                'birthdate' => $form->get('birthdate')->getData()
            ];
            
            
            if ($form->isSubmitted() && $form->isValid()) {
                try {
                    // Create UserDTO from form data
                    $userDTO = new UserDTO(
                        id: $userId,
                        firstName: $form->get('firstName')->getData(),
                        lastName: $form->get('lastName')->getData(),
                        gender: $form->get('gender')->getData(),
                        birthdate: $form->get('birthdate')->getData()
                    );
                    
                    // Call Phoenix API to update user
                    $this->phoenixApiService->update($userDTO);
                    
                    $this->addFlash('success', 'User has been updated successfully');
                    return $this->redirectToRoute('user_show', ['id' => $userId]);
                    
                } catch (\Exception $e) {
                    $this->addFlash('error', 'Failed to update user: ' . $e->getMessage());
                    // Continue to render the form with error
                }
            }
            
            // Check if form has validation errors
            if ($form->isSubmitted() && !$form->isValid()) {
                $this->addFlash('error', 'Please correct the errors below.');
            }
            
            // Always render the form with current data and validation errors
            return $this->render('user/edit.html.twig', [
                'user' => $userData,
                'form' => $form->createView()
            ]);
            
        } catch (InvalidUserIdException $e) {
            $this->addFlash('error', $e->getMessage());
            return $this->redirectToRoute('user_list');
        } catch (\Exception $e) {
            $this->addFlash('error', 'Failed to fetch user data: ' . $e->getMessage());
            return $this->redirectToRoute('user_list');
        }
    }

    #[Route('/users', name: 'user_list', methods: ['GET'])]
    public function list(Request $request): Response
    {
        try {
            $sortField = $this->getSortField($request);
            $sortOrder = $this->getSortOrder($request);
            $lastName = $this->getLastNameFilter($request);
            $filters = [];
            
            if ($sortOrder && $sortField) {
                $filters['sort'] = $sortField;
                $filters['order'] = $sortOrder;
            }
            
            if ($lastName !== null) {
                $filters['last_name'] = $lastName;
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

    /**
     * Retrieves the last_name filter parameter
     *
     * @param Request $request The HTTP request
     * @return string|null The last_name filter or null if not provided or empty
     */
    private function getLastNameFilter(Request $request): ?string
    {
        $lastName = $request->query->get('last_name');
        
        // If null or empty string, return null
        if ($lastName === null || $lastName === '') {
            return null;
        }
        
        return $lastName;
    }

}
