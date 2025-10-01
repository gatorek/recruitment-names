<?php

namespace App\Service;

use App\DTO\UserDTO;
use Symfony\Contracts\HttpClient\HttpClientInterface;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\DecodingExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\RedirectionExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\ServerExceptionInterface;
use Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface;

class PhoenixApiService
{
    public function __construct(
        private HttpClientInterface $httpClient,
        private string $phoenixHost,
        private int $phoenixPort
    ) {
    }

    /**
     * Fetch user data from Phoenix API
     *
     * @param int $id User ID
     * @return UserDTO
     * @throws \Exception
     */
    public function getUser(int $id): UserDTO
    {
        $url = $this->buildUrl("/users/{$id}");
        
        try {
            $response = $this->httpClient->request('GET', $url, [
                'headers' => [
                    'Accept' => 'application/json',
                ],
                'timeout' => 30,
            ]);

            $statusCode = $response->getStatusCode();
            
            if ($statusCode !== 200) {
                throw new \Exception("API returned status code: {$statusCode}");
            }

            $responseData = $response->toArray();
            
            if (empty($responseData) || !isset($responseData['data'])) {
                throw new \Exception("User with ID {$id} not found");
            }

            $data = $responseData['data'];
            
            if (empty($data)) {
                throw new \Exception("User with ID {$id} not found");
            }

            return UserDTO::fromArray($data);

        } catch (ClientExceptionInterface|DecodingExceptionInterface|RedirectionExceptionInterface|ServerExceptionInterface|TransportExceptionInterface $e) {
            throw new \Exception("Failed to fetch user data: " . $e->getMessage(), 0, $e);
        }
    }

    /**
     * List users with filtering and sorting options
     *
     * @param array $filters Optional filters:
     *   - first_name: Filter by first name (partial match)
     *   - last_name: Filter by last name (partial match)
     *   - gender: Filter by gender (male/female)
     *   - birthdate_from: Filter by birthdate from (YYYY-MM-DD)
     *   - birthdate_to: Filter by birthdate to (YYYY-MM-DD)
     *   - sort: Sort by field (first_name, last_name, gender, birthdate)
     *   - order: Sort order (asc/desc, defaults to asc)
     * @return array Array of UserDTO objects
     * @throws \Exception
     */
    public function listUsers(array $filters = []): array
    {
        $queryParams = $this->buildQueryParams($filters);
        $url = $this->buildUrl('/users' . $queryParams);
        
        try {
            $response = $this->httpClient->request('GET', $url, [
                'headers' => [
                    'Accept' => 'application/json',
                ],
                'timeout' => 30,
            ]);

            $statusCode = $response->getStatusCode();
            
            if ($statusCode !== 200) {
                throw new \Exception("API returned status code: {$statusCode}");
            }

            $responseData = $response->toArray();
            
            if (!isset($responseData['data']) || !is_array($responseData['data'])) {
                throw new \Exception("Invalid response format from API");
            }

            $users = [];
            foreach ($responseData['data'] as $userData) {
                $users[] = UserDTO::fromArray($userData);
            }

            return $users;

        } catch (ClientExceptionInterface|DecodingExceptionInterface|RedirectionExceptionInterface|ServerExceptionInterface|TransportExceptionInterface $e) {
            throw new \Exception("Failed to fetch users list: " . $e->getMessage(), 0, $e);
        }
    }

    /**
     * Build full URL to Phoenix API
     */
    private function buildUrl(string $endpoint): string
    {
        return "http://{$this->phoenixHost}:{$this->phoenixPort}{$endpoint}";
    }

    /**
     * Build query parameters string from filters array
     */
    private function buildQueryParams(array $filters): string
    {
        $validFilters = array_intersect_key($filters, array_flip([
            'first_name',
            'last_name', 
            'gender',
            'birthdate_from',
            'birthdate_to',
            'sort',
            'order'
        ]));

        // Remove null and empty values
        $validFilters = array_filter($validFilters, function($value) {
            return $value !== null && $value !== '';
        });

        if (empty($validFilters)) {
            return '';
        }

        return '?' . http_build_query($validFilters);
    }
}
