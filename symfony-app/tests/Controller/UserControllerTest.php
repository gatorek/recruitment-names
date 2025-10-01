<?php

namespace App\Tests\Controller;

use App\DTO\UserDTO;
use App\Service\PhoenixApiService;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
use Symfony\Component\HttpFoundation\Response;

class UserControllerTest extends WebTestCase
{
    public function testShowUserSuccess(): void
    {   
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockUser = new UserDTO(
            id: 1,
            firstName: 'WIOLETTA',
            lastName: 'GRABOWSKA',
            gender: 'female',
            birthdate: new \DateTime('1992-06-16')
        );
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('getUser')
            ->with(1)
            ->willReturn($mockUser);
        
        // Set mock in container
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users/1');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if first and last name are displayed
        $this->assertSelectorTextContains('.user-name', 'WIOLETTA GRABOWSKA');
        
        // Check if ID is displayed
        $this->assertSelectorTextContains('.user-id', 'ID: 1');
        
        // Check user details - each element separately
        $this->assertSelectorTextContains('.detail-row:contains("First Name:")', 'WIOLETTA');
        $this->assertSelectorTextContains('.detail-row:contains("Last Name:")', 'GRABOWSKA');
        $this->assertSelectorTextContains('.gender-badge', 'Female');
        $this->assertSelectorTextContains('.detail-row:contains("Birth Date:")', '16.06.1992');
        
        // Check if back link exists
        $this->assertSelectorExists('.back-link');
        $this->assertSelectorTextContains('.back-link', 'Back to Home');
    }
    
    public function testShowUserNotFound(): void
    {        
        $client = static::createClient();
        
        // Mock PhoenixApiService with error
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('getUser')
            ->with(999)
            ->willThrowException(new \Exception('User with ID 999 not found'));
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $client->request('GET', '/users/999');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if error page is displayed
        $this->assertSelectorTextContains('.error-title', 'An Error Occurred');
        $this->assertSelectorTextContains('.error-message', 'User with ID 999 not found');
        
        // Check if back link exists
        $this->assertSelectorExists('.back-link');
    }
    
    public function testShowUserWithInvalidId(): void
    {
        // Set environment variables for tests
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->never())
            ->method('getUser');
        
        $client = static::createClient();
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        // Test with invalid ID (non-numeric)
        $client->request('GET', '/users/invalid');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check that error page is displayed
        $this->assertSelectorTextContains('.error-title', 'An Error Occurred');
        $this->assertSelectorTextContains('.error-message', 'Invalid user ID \'invalid\'. Please provide a valid positive number.');
    }
    
    public function testShowUserWithNegativeId(): void
    {
        // Mock PhoenixApiService to ensure getUser is never called for negative ID
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->never())
            ->method('getUser');

        $client = static::createClient();
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        // Test with negative ID
        $client->request('GET', '/users/-1');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check that error page is displayed
        $this->assertSelectorTextContains('.error-title', 'An Error Occurred');
        $this->assertSelectorTextContains('.error-message', 'Invalid user ID \'-1\'. Please provide a valid positive number.');
    }
    
    public function testShowUserWithZeroId(): void
    {
        // Mock PhoenixApiService to ensure getUser is never called for zero ID
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->never())
            ->method('getUser');

        $client = static::createClient();
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        // Test with zero ID
        $client->request('GET', '/users/0');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check that error page is displayed
        $this->assertSelectorTextContains('.error-title', 'An Error Occurred');
        $this->assertSelectorTextContains('.error-message', 'Invalid user ID \'0\'. Please provide a valid positive number.');
    }
    
    public function testShowUserRoute(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockUser = new UserDTO(
            id: 1,
            firstName: 'JAN',
            lastName: 'KOWALSKI',
            gender: 'male',
            birthdate: new \DateTime('1985-03-15')
        );
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('getUser')
            ->with(1)
            ->willReturn($mockUser);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $client->request('GET', '/users/1');
        
        $this->assertResponseIsSuccessful();
        
        // Check if routing works correctly
        $this->assertRouteSame('user_show', ['id' => '1']);
    }
    
    public function testShowUserPageStructure(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockUser = new UserDTO(
            id: 2,
            firstName: 'ANNA',
            lastName: 'NOWAK',
            gender: 'female',
            birthdate: new \DateTime('1990-12-25')
        );
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('getUser')
            ->with(2)
            ->willReturn($mockUser);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users/2');
        
        $this->assertResponseIsSuccessful();
        
        // Check HTML structure
        $this->assertSelectorExists('.user-container');
        $this->assertSelectorExists('.user-header');
        $this->assertSelectorExists('.user-name');
        $this->assertSelectorExists('.user-id');
        $this->assertSelectorExists('.user-details');
        $this->assertSelectorExists('.detail-row');
        $this->assertSelectorExists('.gender-badge');
    }
    
    public function testShowUserGenderDisplay(): void
    {
        $client = static::createClient();
        
        // Test for male user
        $mockUser = new UserDTO(
            id: 3,
            firstName: 'PIOTR',
            lastName: 'KOWALSKI',
            gender: 'male',
            birthdate: new \DateTime('1988-07-10')
        );
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('getUser')
            ->with(3)
            ->willReturn($mockUser);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users/3');
        
        $this->assertResponseIsSuccessful();
        
        // Check if gender is displayed correctly
        $this->assertSelectorTextContains('.gender-badge', 'Male');
        $this->assertSelectorExists('.gender-male');
    }
    
}
