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
     * Build full URL to Phoenix API
     */
    private function buildUrl(string $endpoint): string
    {
        return "http://{$this->phoenixHost}:{$this->phoenixPort}{$endpoint}";
    }
}
