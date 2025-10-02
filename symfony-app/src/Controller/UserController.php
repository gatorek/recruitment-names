<?php

namespace App\Controller;

use App\DTO\UserDTO;
use App\Exception\InvalidUserIdException;
use App\Form\UserCreateType;
use App\Form\UserEditType;
use App\Service\PhoenixApiService;
use Exception;
use InvalidArgumentException;
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
    public function create(): Response
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
            } catch (Exception $e) {
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
        } catch (Exception $e) {
            $this->addFlash('error', 'Failed to fetch user data: ' . $e->getMessage());
            return $this->redirectToRoute('user_list');
        }
    }

    #[Route('/users/{id}/edit', name: 'user_edit', methods: ['GET'])]
    public function edit(string $id): Response
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
        } catch (Exception $e) {
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
                } catch (Exception $e) {
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
        } catch (Exception $e) {
            $this->addFlash('error', 'Failed to fetch user data: ' . $e->getMessage());
            return $this->redirectToRoute('user_list');
        }
    }

    #[Route('/users/{id}', name: 'user_delete', methods: ['DELETE', 'POST'])]
    public function delete(string $id): RedirectResponse
    {
        try {
            $userId = $this->validateAndParseUserId($id);

            // Call Phoenix API to delete user
            $this->phoenixApiService->delete($userId);

            $this->addFlash('success', 'User has been deleted successfully');
        } catch (InvalidUserIdException $e) {
            $this->addFlash('error', $e->getMessage());
        } catch (Exception $e) {
            $this->addFlash('error', 'Failed to delete user: ' . $e->getMessage());
        }

        return $this->redirectToRoute('user_list');
    }

    #[Route('/users', name: 'user_list', methods: ['GET'])]
    public function list(Request $request): Response
    {
        try {
            $filterData = $this->extractFilterData($request);
            
            // Validate birthdate range
            if ($this->isInvalidBirthdateRange($filterData['birthdateFrom'], $filterData['birthdateTo'])) {
                $this->addFlash('error', 'Birthdate "from" cannot be greater than birthdate "to".');
                return $this->renderUserList([], $filterData);
            }

            $filters = $this->buildFilters($filterData);
            $users = $this->phoenixApiService->listUsers($filters);

            return $this->renderUserList($users, $filterData);
        } catch (InvalidArgumentException $e) {
            $this->addFlash('error', 'Invalid sorting parameter: ' . $e->getMessage());
            return $this->renderUserList([], $this->getEmptyFilterData());
        } catch (Exception $e) {
            $this->addFlash('error', 'Failed to fetch users list: ' . $e->getMessage());
            return $this->renderUserList([], $this->getEmptyFilterData());
        }
    }

    /**
     * Validates and parses the user ID parameter
     *
     * @param string $userId The ID parameter from the URL
     * @return int The validated and parsed user ID
     * @throws InvalidUserIdException When the ID is invalid
     */
    private function validateAndParseUserId(string $userId): int
    {
        // Check if the ID is numeric
        if (!is_numeric($userId)) {
            throw new InvalidUserIdException($userId);
        }

        $parsedUserId = (int)$userId;

        // Check if the ID is positive
        if ($parsedUserId <= 0) {
            throw new InvalidUserIdException($userId);
        }

        return $parsedUserId;
    }

    /**
     * Validates and retrieves the sort field parameter
     *
     * @param Request $request The HTTP request
     * @return string|null The validated sort field or null if not provided
     * @throws InvalidArgumentException If sort_field has invalid value
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
            throw new InvalidArgumentException("Invalid sort field: {$sortField}");
        }

        return $sortField;
    }

    /**
     * Determines the sort order based on current query parameters
     * Implements cyclic sorting: asc -> desc -> default (null)
     *
     * @param Request $request The HTTP request
     * @return string|null The sort order ('asc', 'desc', or null for default)
     * @throws InvalidArgumentException If sort_order has invalid value
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
                throw new InvalidArgumentException("Invalid sort order: {$currentSort}");
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

    /**
     * Retrieves the first_name filter parameter
     *
     * @param Request $request The HTTP request
     * @return string|null The first_name filter or null if not provided or empty
     */
    private function getFirstNameFilter(Request $request): ?string
    {
        $firstName = $request->query->get('first_name');

        // If null or empty string, return null
        if ($firstName === null || $firstName === '') {
            return null;
        }

        return $firstName;
    }

    /**
     * Retrieves the gender filter parameter
     *
     * @param Request $request The HTTP request
     * @return string|null The gender filter or null if not provided or empty
     */
    private function getGenderFilter(Request $request): ?string
    {
        $gender = $request->query->get('gender');

        // If null or empty string, return null
        if ($gender === null || $gender === '') {
            return null;
        }

        // Validate gender value
        $validGenders = ['male', 'female'];
        if (!in_array($gender, $validGenders, true)) {
            return null;
        }

        return $gender;
    }

    /**
     * Retrieves the birthdate_from filter parameter
     *
     * @param Request $request The HTTP request
     * @return string|null The birthdate_from filter or null if not provided or empty
     */
    private function getBirthdateFromFilter(Request $request): ?string
    {
        $birthdateFrom = $request->query->get('birthdate_from');

        // If null or empty string, return null
        if ($birthdateFrom === null || $birthdateFrom === '') {
            return null;
        }

        // Validate date format (YYYY-MM-DD)
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $birthdateFrom)) {
            return null;
        }

        return $birthdateFrom;
    }

    /**
     * Retrieves the birthdate_to filter parameter
     *
     * @param Request $request The HTTP request
     * @return string|null The birthdate_to filter or null if not provided or empty
     */
    private function getBirthdateToFilter(Request $request): ?string
    {
        $birthdateTo = $request->query->get('birthdate_to');

        // If null or empty string, return null
        if ($birthdateTo === null || $birthdateTo === '') {
            return null;
        }

        // Validate date format (YYYY-MM-DD)
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $birthdateTo)) {
            return null;
        }

        return $birthdateTo;
    }

    /**
     * Extracts all filter data from the request
     */
    private function extractFilterData(Request $request): array
    {
        return [
            'sortField' => $this->getSortField($request),
            'sortOrder' => $this->getSortOrder($request),
            'lastName' => $this->getLastNameFilter($request),
            'firstName' => $this->getFirstNameFilter($request),
            'gender' => $this->getGenderFilter($request),
            'birthdateFrom' => $this->getBirthdateFromFilter($request),
            'birthdateTo' => $this->getBirthdateToFilter($request),
        ];
    }

    /**
     * Builds filters array for API call
     */
    private function buildFilters(array $filterData): array
    {
        $filters = [];

        if ($filterData['sortOrder'] && $filterData['sortField']) {
            $filters['sort'] = $filterData['sortField'];
            $filters['order'] = $filterData['sortOrder'];
        }

        $filterMappings = [
            'lastName' => 'last_name',
            'firstName' => 'first_name',
            'gender' => 'gender',
            'birthdateFrom' => 'birthdate_from',
            'birthdateTo' => 'birthdate_to',
        ];

        foreach ($filterMappings as $key => $apiKey) {
            if ($filterData[$key] !== null) {
                $filters[$apiKey] = $filterData[$key];
            }
        }

        return $filters;
    }

    /**
     * Validates birthdate range
     */
    private function isInvalidBirthdateRange(?string $from, ?string $to): bool
    {
        return $from !== null && $to !== null && $from > $to;
    }

    /**
     * Renders the user list template with data
     */
    private function renderUserList(array $users, array $filterData): Response
    {
        return $this->render('user/list.html.twig', [
            'users' => $users,
            'currentSort' => $filterData['sortOrder'],
            'currentSortField' => $filterData['sortField'],
            'currentLastNameFilter' => $filterData['lastName'],
            'currentFirstNameFilter' => $filterData['firstName'],
            'currentGenderFilter' => $filterData['gender'],
            'currentBirthdateFromFilter' => $filterData['birthdateFrom'],
            'currentBirthdateToFilter' => $filterData['birthdateTo'],
        ]);
    }

    /**
     * Returns empty filter data for error cases
     */
    private function getEmptyFilterData(): array
    {
        return [
            'sortField' => null,
            'sortOrder' => null,
            'lastName' => null,
            'firstName' => null,
            'gender' => null,
            'birthdateFrom' => null,
            'birthdateTo' => null,
        ];
    }
}
