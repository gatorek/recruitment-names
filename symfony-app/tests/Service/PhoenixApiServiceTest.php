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
}
