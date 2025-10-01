<?php

namespace App\Tests\Service;

use App\DTO\UserDTO;
use App\Service\PhoenixApiService;
use PHPUnit\Framework\TestCase;
use Symfony\Component\HttpClient\MockHttpClient;
use Symfony\Component\HttpClient\Response\MockResponse;

class PhoenixApiServiceTest extends TestCase
{
    public function testGetUser(): void
    {
        $mockResponse = new MockResponse(json_encode([
            'data' => [
                'id' => 1,
                'first_name' => 'WIOLETTA',
                'last_name' => 'GRABOWSKA',
                'gender' => 'female',
                'birthdate' => '1992-06-16'
            ]
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = new MockHttpClient($mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $user = $service->getUser(1);

        $this->assertInstanceOf(UserDTO::class, $user);
        $this->assertEquals(1, $user->id);
        $this->assertEquals('WIOLETTA', $user->firstName);
        $this->assertEquals('GRABOWSKA', $user->lastName);
        $this->assertEquals('female', $user->gender);
        $this->assertEquals('1992-06-16', $user->birthdate->format('Y-m-d'));
    }

    public function testGetUserNotFound(): void
    {
        $mockResponse = new MockResponse('', [
            'http_code' => 404
        ]);

        $httpClient = new MockHttpClient($mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('API returned status code: 404');

        $service->getUser(999);
    }

    public function testGetUserWithEmptyData(): void
    {
        $mockResponse = new MockResponse(json_encode([
            'data' => []
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = new MockHttpClient($mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('User with ID 1 not found');

        $service->getUser(1);
    }

    public function testGetUserWithMissingDataWrapper(): void
    {
        $mockResponse = new MockResponse(json_encode([
            'message' => 'User not found'
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = new MockHttpClient($mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('User with ID 1 not found');

        $service->getUser(1);
    }

    public function testListUsers(): void
    {
        $mockResponse = new MockResponse(json_encode([
            'data' => [
                [
                    'id' => 23,
                    'first_name' => 'IRYNA',
                    'last_name' => 'BORKOWSKA',
                    'gender' => 'female',
                    'birthdate' => '2020-09-13'
                ],
                [
                    'id' => 27,
                    'first_name' => 'JAKUB',
                    'last_name' => 'ADAMSKI',
                    'gender' => 'male',
                    'birthdate' => '2021-11-14'
                ]
            ]
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = $this->createMockHttpClientWithoutQuery($mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $users = $service->listUsers();

        $this->assertIsArray($users);
        $this->assertCount(2, $users);
        
        $this->assertInstanceOf(UserDTO::class, $users[0]);
        $this->assertEquals(23, $users[0]->id);
        $this->assertEquals('IRYNA', $users[0]->firstName);
        $this->assertEquals('BORKOWSKA', $users[0]->lastName);
        $this->assertEquals('female', $users[0]->gender);
        $this->assertEquals('2020-09-13', $users[0]->birthdate->format('Y-m-d'));

        $this->assertInstanceOf(UserDTO::class, $users[1]);
        $this->assertEquals(27, $users[1]->id);
        $this->assertEquals('JAKUB', $users[1]->firstName);
        $this->assertEquals('ADAMSKI', $users[1]->lastName);
        $this->assertEquals('male', $users[1]->gender);
        $this->assertEquals('2021-11-14', $users[1]->birthdate->format('Y-m-d'));
    }

    public function testListUsersWithFilters(): void
    {
        $expectedQueryParams = [
            'first_name' => 'JOHN',
            'gender' => 'male',
            'sort' => 'first_name',
            'order' => 'asc'
        ];

        $mockResponse = new MockResponse(json_encode([
            'data' => [
                [
                    'id' => 1,
                    'first_name' => 'JOHN',
                    'last_name' => 'DOE',
                    'gender' => 'male',
                    'birthdate' => '1990-01-01'
                ]
            ]
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = $this->createMockHttpClientWithQueryVerification($expectedQueryParams, $mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $filters = [
            'first_name' => 'JOHN',
            'gender' => 'male',
            'sort' => 'first_name',
            'order' => 'asc'
        ];

        $users = $service->listUsers($filters);

        $this->assertIsArray($users);
        $this->assertCount(1, $users);
        $this->assertInstanceOf(UserDTO::class, $users[0]);
        $this->assertEquals('JOHN', $users[0]->firstName);
        $this->assertEquals('male', $users[0]->gender);
    }

    public function testListUsersWithEmptyFilters(): void
    {
        $mockResponse = new MockResponse(json_encode([
            'data' => []
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = $this->createMockHttpClientWithoutQuery($mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $users = $service->listUsers([]);

        $this->assertIsArray($users);
        $this->assertCount(0, $users);
    }

    public function testListUsersWithNullAndEmptyFilters(): void
    {
        $expectedQueryParams = [
            'gender' => 'male' // Only non-null, non-empty values should be included
        ];

        $mockResponse = new MockResponse(json_encode([
            'data' => []
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = $this->createMockHttpClientWithQueryVerification($expectedQueryParams, $mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $filters = [
            'first_name' => null,
            'last_name' => '',
            'gender' => 'male', // This should be included
            'sort' => null,
            'order' => ''
        ];

        $users = $service->listUsers($filters);

        $this->assertIsArray($users);
        $this->assertCount(0, $users);
    }

    public function testListUsersWithInvalidFilters(): void
    {
        $expectedQueryParams = [
            'first_name' => 'JOHN' // Only valid parameters should be included
        ];

        $mockResponse = new MockResponse(json_encode([
            'data' => []
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = $this->createMockHttpClientWithQueryVerification($expectedQueryParams, $mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $filters = [
            'invalid_param' => 'value', // Should be ignored
            'first_name' => 'JOHN',     // Should be included
            'another_invalid' => 'test' // Should be ignored
        ];

        $users = $service->listUsers($filters);

        $this->assertIsArray($users);
        $this->assertCount(0, $users);
    }

    public function testListUsersApiError(): void
    {
        $mockResponse = new MockResponse('', [
            'http_code' => 500
        ]);

        $httpClient = new MockHttpClient($mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('API returned status code: 500');

        $service->listUsers();
    }

    public function testListUsersInvalidResponseFormat(): void
    {
        $mockResponse = new MockResponse(json_encode([
            'users' => [] // Wrong key, should be 'data'
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = new MockHttpClient($mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Invalid response format from API');

        $service->listUsers();
    }

    public function testListUsersWithNonArrayData(): void
    {
        $mockResponse = new MockResponse(json_encode([
            'data' => 'not_an_array'
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = new MockHttpClient($mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Invalid response format from API');

        $service->listUsers();
    }

    public function testListUsersWithAllValidFilters(): void
    {
        $expectedQueryParams = [
            'first_name' => 'John',
            'last_name' => 'Doe',
            'gender' => 'male',
            'birthdate_from' => '1990-01-01',
            'birthdate_to' => '2000-12-31',
            'sort' => 'first_name',
            'order' => 'desc'
        ];

        $mockResponse = new MockResponse(json_encode([
            'data' => []
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = $this->createMockHttpClientWithQueryVerification($expectedQueryParams, $mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $filters = [
            'first_name' => 'John',
            'last_name' => 'Doe',
            'gender' => 'male',
            'birthdate_from' => '1990-01-01',
            'birthdate_to' => '2000-12-31',
            'sort' => 'first_name',
            'order' => 'desc'
        ];

        $users = $service->listUsers($filters);

        $this->assertIsArray($users);
        $this->assertCount(0, $users);
    }
    
    /**
     * Create MockHttpClient with query parameters verification
     */
    private function createMockHttpClientWithQueryVerification(array $expectedQueryParams, MockResponse $mockResponse): MockHttpClient
    {
        return new MockHttpClient(function ($method, $url, $options) use ($expectedQueryParams, $mockResponse) {
            // Check HTTP method
            $this->assertEquals('GET', $method);
            
            // Check URL
            $this->assertStringStartsWith('http://localhost:4000/users', $url);
            
            // Check query parameters
            $parsedUrl = parse_url($url);
            $this->assertArrayHasKey('query', $parsedUrl);
            
            parse_str($parsedUrl['query'], $actualQueryParams);
            $this->assertEquals($expectedQueryParams, $actualQueryParams);

            return $mockResponse;
        });
    }

    public function testUpdate(): void
    {
        $userData = [
            'id' => 1,
            'first_name' => 'JANE',
            'last_name' => 'SMITH',
            'gender' => 'female',
            'birthdate' => '1995-05-15'
        ];

        $mockResponse = new MockResponse(json_encode([
            'data' => $userData
        ]), [
            'http_code' => 200,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = $this->createMockHttpClientForUpdate($userData, $mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $user = new UserDTO(
            id: 1,
            firstName: 'JANE',
            lastName: 'SMITH',
            gender: 'female',
            birthdate: new \DateTime('1995-05-15')
        );

        $updatedUser = $service->update($user);

        $this->assertInstanceOf(UserDTO::class, $updatedUser);
        $this->assertEquals(1, $updatedUser->id);
        $this->assertEquals('JANE', $updatedUser->firstName);
        $this->assertEquals('SMITH', $updatedUser->lastName);
        $this->assertEquals('female', $updatedUser->gender);
        $this->assertEquals('1995-05-15', $updatedUser->birthdate->format('Y-m-d'));
    }

    public function testUpdateNotFound(): void
    {
        $userData = [
            'id' => 999,
            'first_name' => 'JANE',
            'last_name' => 'SMITH',
            'gender' => 'female',
            'birthdate' => '1995-05-15'
        ];

        $mockResponse = new MockResponse('', [
            'http_code' => 404
        ]);

        $httpClient = $this->createMockHttpClientForUpdate($userData, $mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $user = new UserDTO(
            id: 999,
            firstName: 'JANE',
            lastName: 'SMITH',
            gender: 'female',
            birthdate: new \DateTime('1995-05-15')
        );

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('API returned status code: 404');

        $service->update($user);
    }

    public function testUpdateApiError(): void
    {
        $userData = [
            'id' => 1,
            'first_name' => 'JANE',
            'last_name' => 'SMITH',
            'gender' => 'female',
            'birthdate' => '1995-05-15'
        ];

        $mockResponse = new MockResponse('', [
            'http_code' => 500
        ]);

        $httpClient = $this->createMockHttpClientForUpdate($userData, $mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $user = new UserDTO(
            id: 1,
            firstName: 'JANE',
            lastName: 'SMITH',
            gender: 'female',
            birthdate: new \DateTime('1995-05-15')
        );

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('API returned status code: 500');

        $service->update($user);
    }

    public function testUpdateWithValidationError(): void
    {
        $userData = [
            'id' => 1,
            'first_name' => 'JANE',
            'last_name' => 'SMITH',
            'gender' => 'female',
            'birthdate' => '1995-05-15'
        ];

        $mockResponse = new MockResponse(json_encode([
            'errors' => [
                'first_name' => ['can\'t be blank']
            ]
        ]), [
            'http_code' => 422,
            'response_headers' => ['Content-Type' => 'application/json']
        ]);

        $httpClient = $this->createMockHttpClientForUpdate($userData, $mockResponse);
        $service = new PhoenixApiService($httpClient, 'localhost', 4000);

        $user = new UserDTO(
            id: 1,
            firstName: 'JANE',
            lastName: 'SMITH',
            gender: 'female',
            birthdate: new \DateTime('1995-05-15')
        );

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('API returned status code: 422');

        $service->update($user);
    }

    /**
     * Create MockHttpClient for update operations with request body verification
     */
    private function createMockHttpClientForUpdate(array $expectedUserData, MockResponse $mockResponse): MockHttpClient
    {
        return new MockHttpClient(function ($method, $url, $options) use ($expectedUserData, $mockResponse) {
            // Check HTTP method
            $this->assertEquals('PUT', $method);
            
            // Check URL
            $this->assertEquals("http://localhost:4000/users/{$expectedUserData['id']}", $url);
            
            // Check request body
            $this->assertArrayHasKey('body', $options);
            $this->assertEquals(json_encode($expectedUserData), $options['body']);

            return $mockResponse;
        });
    }

    /**
     * Create MockHttpClient without query parameters verification (for empty/no params)
     */
    private function createMockHttpClientWithoutQuery(MockResponse $mockResponse): MockHttpClient
    {
        return new MockHttpClient(function ($method, $url, $options) use ($mockResponse) {
            // Check HTTP method
            $this->assertEquals('GET', $method);
            
            // Check URL - should be without query string
            $this->assertEquals('http://localhost:4000/users', $url);
            
            // Additional verification: ensure no query parameters exist
            $parsedUrl = parse_url($url);
            $this->assertArrayNotHasKey('query', $parsedUrl);

            return $mockResponse;
        });
    }
}
