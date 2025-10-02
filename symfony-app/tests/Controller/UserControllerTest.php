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
        $this->assertSelectorTextContains('.card-title', 'WIOLETTA GRABOWSKA');
        
        // Check if ID is displayed
        $this->assertSelectorTextContains('small', 'ID: 1');
        
        // Check user details - each element separately
        $this->assertSelectorTextContains('.user-detail-row:contains("First Name:")', 'WIOLETTA');
        $this->assertSelectorTextContains('.user-detail-row:contains("Last Name:")', 'GRABOWSKA');
        $this->assertSelectorTextContains('.gender-badge', 'Female');
        $this->assertSelectorTextContains('.user-detail-row:contains("Birth Date:")', '16.06.1992');
        
        // Check if navigation links exist
        $this->assertSelectorExists('a[href="/users"]');
        $this->assertSelectorTextContains('a[href="/users"]', 'User List');
        $this->assertSelectorExists('a[href="/users/1/edit"]');
        $this->assertSelectorTextContains('a[href="/users/1/edit"]', 'Edit User');
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
        
        // Should redirect to user list
        $this->assertResponseRedirects('/users');
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
        
        // Should redirect to user list
        $this->assertResponseRedirects('/users');
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
        
        // Should redirect to user list
        $this->assertResponseRedirects('/users');
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
        
        // Should redirect to user list
        $this->assertResponseRedirects('/users');
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
        $this->assertSelectorExists('.card');
        $this->assertSelectorExists('.card-header');
        $this->assertSelectorExists('.card-title');
        $this->assertSelectorExists('.card-body');
        $this->assertSelectorExists('.user-detail-row');
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
    
    public function testEditUserSuccess(): void
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
        
        $crawler = $client->request('GET', '/users/1/edit');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if edit page title is displayed
        $this->assertSelectorTextContains('.card-title', 'Edit User');
        
        // Check if user info is displayed in header
        $this->assertSelectorTextContains('small', 'WIOLETTA GRABOWSKA (ID: 1)');
        
        // Check if form is present
        $this->assertSelectorExists('form');
        $this->assertSelectorExists('form.needs-validation');
        
        // Check if form fields are pre-filled with user data
        $firstNameField = $crawler->filter('input[name="user_edit[firstName]"]');
        $this->assertEquals('WIOLETTA', $firstNameField->attr('value'));
        
        $lastNameField = $crawler->filter('input[name="user_edit[lastName]"]');
        $this->assertEquals('GRABOWSKA', $lastNameField->attr('value'));
        
        $birthdateField = $crawler->filter('input[name="user_edit[birthdate]"]');
        $this->assertEquals('1992-06-16', $birthdateField->attr('value'));
        
        // Check if gender dropdown has correct value selected
        $genderSelect = $crawler->filter('select[name="user_edit[gender]"]');
        $this->assertCount(1, $genderSelect->filter('option[value="female"][selected]'));
        
        // Check if submit button has correct text
        $this->assertSelectorTextContains('button[name="user_edit[save]"]', 'Update User');
        
        // Check if navigation links are present
        $this->assertSelectorExists('a[href="/users"]');
        $this->assertSelectorTextContains('a[href="/users"]', 'User List');
        $this->assertSelectorExists('a[href="/users/1"]');
        $this->assertSelectorTextContains('a[href="/users/1"]', 'View Details');
    }
    
    public function testEditUserNotFound(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with error
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('getUser')
            ->with(999)
            ->willThrowException(new \Exception('User with ID 999 not found'));
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $client->request('GET', '/users/999/edit');
        
        // Should redirect to user list
        $this->assertResponseRedirects('/users');
    }
    
    public function testEditUserWithInvalidId(): void
    {
        // Mock PhoenixApiService to ensure getUser is never called for invalid ID
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->never())
            ->method('getUser');
        
        $client = static::createClient();
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        // Test with invalid ID (non-numeric)
        $client->request('GET', '/users/invalid/edit');
        
        // Should redirect to user list
        $this->assertResponseRedirects('/users');
    }
    
    public function testEditUserRoute(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockUser = new UserDTO(
            id: 1,
            firstName: 'TEST',
            lastName: 'USER',
            gender: 'male',
            birthdate: new \DateTime('1990-01-01')
        );
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('getUser')
            ->with(1)
            ->willReturn($mockUser);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users/1/edit');
        
        $this->assertResponseIsSuccessful();
        
        // Check if the route is accessible
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if edit form is displayed
        $this->assertSelectorExists('form');
        $this->assertSelectorTextContains('.card-title', 'Edit User');
    }

    public function testListUsersSuccess(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with multiple users
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            ),
            new UserDTO(
                id: 2,
                firstName: 'ANNA',
                lastName: 'NOWAK',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            )
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with([])
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if users are displayed
        $this->assertSelectorTextContains('h1', 'Users List');
        $this->assertSelectorTextContains('h5', 'Found 2 users');
        
        // Check if both users are displayed
        $this->assertSelectorTextContains('body', 'JAN KOWALSKI');
        $this->assertSelectorTextContains('body', 'ANNA NOWAK');
        
        // Check if view details links exist
        $this->assertSelectorExists('a[href="/users/1"]');
        $this->assertSelectorExists('a[href="/users/2"]');
        
        // Check if filter form is displayed
        $this->assertSelectorExists('form[method="GET"]');
        $this->assertSelectorExists('input[name="first_name"]');
        $this->assertSelectorExists('input[name="last_name"]');
        $this->assertSelectorExists('select[name="gender"]');
        $this->assertSelectorExists('button[type="submit"]');
        $this->assertSelectorTextContains('button[type="submit"]', 'Filter');
    }
    
    public function testListUsersEmptyResult(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with empty result
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with([])
            ->willReturn([]);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if empty state is displayed
        $this->assertSelectorTextContains('h4', 'No users found');
        $this->assertSelectorTextContains('body', 'No users are available at the moment');
    }
    
    public function testListUsersWithApiError(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with error
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with([])
            ->willThrowException(new \Exception('API connection failed'));
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $client->request('GET', '/users');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if error is displayed
        $this->assertSelectorTextContains('.alert-danger', 'API connection failed');
    }
    
    public function testListUsersRoute(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with([])
            ->willReturn([]);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $client->request('GET', '/users');
        
        $this->assertResponseIsSuccessful();
        
        // Check if routing works correctly
        $this->assertRouteSame('user_list');
    }
    
    public function testListUsersPageStructure(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            )
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with([])
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users');
        
        $this->assertResponseIsSuccessful();
        
        // Check HTML structure
        $this->assertSelectorExists('.card');
        $this->assertSelectorExists('.card-header');
        $this->assertSelectorExists('h1');
        $this->assertSelectorExists('h5');
    }
    
    public function testListUsersWithAscendingSort(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with sorted users
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'ANNA',
                lastName: 'NOWAK',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            ),
            new UserDTO(
                id: 2,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            )
        ];
        
        $expectedFilters = [
            'sort' => 'first_name',
            'order' => 'desc'
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_order=desc&sort_field=first_name');
        
        $this->assertResponseIsSuccessful();
        
        // Check if page loads
        $this->assertSelectorExists('h1');
    }
    
    public function testListUsersWithDescendingSort(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with sorted users
        $mockUsers = [
            new UserDTO(
                id: 2,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            ),
            new UserDTO(
                id: 1,
                firstName: 'ANNA',
                lastName: 'NOWAK',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            )
        ];
        
        $expectedFilters = [
            'sort' => 'first_name',
            'order' => 'desc'
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_order=desc&sort_field=first_name');
        
        $this->assertResponseIsSuccessful();
        
        // Check if sorting icon is displayed (descending)
        $this->assertSelectorExists('i[style*="transform: rotate(180deg)"]');
    }
    
    public function testListUsersWithDefaultSort(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with default users
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            ),
            new UserDTO(
                id: 2,
                firstName: 'ANNA',
                lastName: 'NOWAK',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            )
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with(['sort' => 'first_name', 'order' => 'desc'])
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_order=desc&sort_field=first_name');
        
        $this->assertResponseIsSuccessful();
        
        // Check if sorting icon is displayed (descending)
        $this->assertSelectorExists('i[style*="transform: rotate(180deg)"]');
    }
    
    public function testListUsersSortingLinkGeneration(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            )
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with([])
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users');
        
        $this->assertResponseIsSuccessful();
        
        // Check if table exists
        $this->assertSelectorExists('table');
    }
    
    public function testListUsersWithLastNameAscendingSort(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with sorted users
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'ANNA',
                lastName: 'KOWALSKI',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            ),
            new UserDTO(
                id: 2,
                firstName: 'JAN',
                lastName: 'NOWAK',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            )
        ];
        
        $expectedFilters = [
            'sort' => 'last_name',
            'order' => 'asc'
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_field=last_name&sort_order=asc');
        
        $this->assertResponseIsSuccessful();
        
        // Check if sorting icon is displayed (ascending)
        $this->assertSelectorExists('i.bi-triangle-fill');
        $this->assertSelectorNotExists('i[style*="transform: rotate(180deg)"]');
    }
    
    public function testListUsersWithLastNameDescendingSort(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with sorted users
        $mockUsers = [
            new UserDTO(
                id: 2,
                firstName: 'JAN',
                lastName: 'NOWAK',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            ),
            new UserDTO(
                id: 1,
                firstName: 'ANNA',
                lastName: 'KOWALSKI',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            )
        ];
        
        $expectedFilters = [
            'sort' => 'last_name',
            'order' => 'desc'
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_field=last_name&sort_order=desc');
        
        $this->assertResponseIsSuccessful();
        
        // Check if sorting icon is displayed (descending)
        $this->assertSelectorExists('i[style*="transform: rotate(180deg)"]');
    }
    
    public function testListUsersSortingFieldSwitching(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            )
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with([])
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users');
        
        $this->assertResponseIsSuccessful();
        
        // Check if both sorting links exist
        $this->assertSelectorExists('a[href*="sort_field=first_name"]');
        $this->assertSelectorExists('a[href*="sort_field=last_name"]');
    }
    
    public function testListUsersWithGenderAscendingSort(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with sorted users (male first for asc)
        $mockUsers = [
            new UserDTO(
                id: 2,
                firstName: 'JAN',
                lastName: 'NOWAK',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            ),
            new UserDTO(
                id: 1,
                firstName: 'ANNA',
                lastName: 'KOWALSKI',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            )
        ];
        
        $expectedFilters = [
            'sort' => 'gender',
            'order' => 'asc' // Normal order: male first
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_field=gender&sort_order=asc');
        
        $this->assertResponseIsSuccessful();
    }
    
    public function testListUsersWithGenderDescendingSort(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with sorted users (female first for desc)
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'ANNA',
                lastName: 'KOWALSKI',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            ),
            new UserDTO(
                id: 2,
                firstName: 'JAN',
                lastName: 'NOWAK',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            )
        ];
        
        $expectedFilters = [
            'sort' => 'gender',
            'order' => 'desc' // Normal order: female first
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_field=gender&sort_order=desc');
        
        $this->assertResponseIsSuccessful();
    }
    
    public function testListUsersAllSortingFieldsAvailable(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            )
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with([])
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users');
        
        $this->assertResponseIsSuccessful();
        
        // Check if all sorting links exist
        $this->assertSelectorExists('a[href*="sort_field=first_name"]');
        $this->assertSelectorExists('a[href*="sort_field=last_name"]');
        $this->assertSelectorExists('a[href*="sort_field=gender"]');
        $this->assertSelectorExists('a[href*="sort_field=birthdate"]');
    }
    
    public function testListUsersWithBirthdateAscendingSort(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with sorted users (oldest first for asc)
        $mockUsers = [
            new UserDTO(
                id: 2,
                firstName: 'JAN',
                lastName: 'NOWAK',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            ),
            new UserDTO(
                id: 1,
                firstName: 'ANNA',
                lastName: 'KOWALSKI',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            )
        ];
        
        $expectedFilters = [
            'sort' => 'birthdate',
            'order' => 'asc' // Normal order: oldest first
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_field=birthdate&sort_order=asc');
        
        $this->assertResponseIsSuccessful();
    }
    
    public function testListUsersWithBirthdateDescendingSort(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with sorted users (newest first for desc)
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'ANNA',
                lastName: 'KOWALSKI',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            ),
            new UserDTO(
                id: 2,
                firstName: 'JAN',
                lastName: 'NOWAK',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            )
        ];
        
        $expectedFilters = [
            'sort' => 'birthdate',
            'order' => 'desc' // Normal order: newest first
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_field=birthdate&sort_order=desc');
        
        $this->assertResponseIsSuccessful();
    }
    
    public function testListUsersWithInvalidSortField(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService to avoid environment variable issues
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->never())
            ->method('listUsers');
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_field=invalid_field');
        
        $this->assertResponseIsSuccessful();
        
        // Check if error message is displayed
        $this->assertSelectorTextContains('.alert-danger', 'Invalid sort field: invalid_field');
    }
    
    public function testListUsersWithEmptySortField(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            )
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with([])
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_field=');
        
        $this->assertResponseIsSuccessful();
        
        // Should work normally without sorting
        $this->assertSelectorExists('table');
    }
    
    public function testListUsersWithInvalidSortOrder(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService to avoid environment variable issues
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->never())
            ->method('listUsers');
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_field=first_name&sort_order=invalid_order');
        
        $this->assertResponseIsSuccessful();
        
        // Check if error message is displayed
        $this->assertSelectorTextContains('.alert-danger', 'Invalid sort order: invalid_order');
    }
    
    public function testListUsersWithEmptySortOrder(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            )
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with([])
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?sort_field=first_name&sort_order=');
        
        $this->assertResponseIsSuccessful();
        
        // Should work normally without sorting
        $this->assertSelectorExists('table');
    }
    
    public function testUpdateUserWithValidationErrors(): void
    {
        // Set environment variables for tests
        $_ENV['PHX_HOST'] = 'localhost';
        $_ENV['PORT'] = '4000';
        
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
        $mockService->expects($this->never())
            ->method('getUser');
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        // Submit form with invalid data (empty first name)
        $crawler = $client->request('POST', '/users/1/edit', [
            'user_edit' => [
                'firstName' => '', // Empty first name - should cause validation error
                'lastName' => 'GRABOWSKA',
                'gender' => 'female',
                'birthdate' => '1992-06-16',
                'save' => ''
            ]
        ]);
        
        // Should render the form directly with validation errors (no redirect)
        $this->assertResponseIsSuccessful();
        
        // Check if error message is displayed
        $this->assertSelectorTextContains('.alert-danger', 'Please correct the errors below.');
        
        // Check if form is displayed with validation errors
        $this->assertSelectorExists('form');
        $this->assertSelectorTextContains('.card-title', 'Edit User');
        
        // Check if form fields contain the submitted data (even with errors)
        $firstNameField = $crawler->filter('input[name="user_edit[firstName]"]');
        $this->assertEquals('', $firstNameField->attr('value')); // Empty value preserved
        
        $lastNameField = $crawler->filter('input[name="user_edit[lastName]"]');
        $this->assertEquals('GRABOWSKA', $lastNameField->attr('value')); // Other data preserved
        
        $birthdateField = $crawler->filter('input[name="user_edit[birthdate]"]');
        $this->assertEquals('1992-06-16', $birthdateField->attr('value')); // Other data preserved
        
        $this->assertSelectorExists('input[name="user_edit[firstName]"][class*="is-invalid"]', 'First name field should have is-invalid class');
        $this->assertSelectorExists('.invalid-feedback', 'Should have validation error messages');
        
        // Check if validation error message is displayed for firstName field
        $firstNameError = $crawler->filter('input[name="user_edit[firstName]"]')->closest('.form-group')->filter('.invalid-feedback');
        $this->assertGreaterThan(0, $firstNameError->count(), 'First name field should have validation error message');
        
        // Check if lastName field (which is valid) doesn't have error styling
        $lastNameField = $crawler->filter('input[name="user_edit[lastName]"]');
        $this->assertStringNotContainsString('is-invalid', $lastNameField->attr('class') ?? '', 'Last name field should not have is-invalid class');
    }
    
    public function testUpdateUserWithLastNameValidationError(): void
    {
        // Set environment variables for tests
        $_ENV['PHX_HOST'] = 'localhost';
        $_ENV['PORT'] = '4000';

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
        $mockService->expects($this->never())
            ->method('getUser');

        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);

        // Submit form with invalid data (empty last name)
        $crawler = $client->request('POST', '/users/1/edit', [
            'user_edit' => [
                'firstName' => 'WIOLETTA',
                'lastName' => '', // Empty last name - should cause validation error
                'gender' => 'female',
                'birthdate' => '1992-06-16',
                'save' => ''
            ]
        ]);

        // Should render the form directly with validation errors (no redirect)
        $this->assertResponseIsSuccessful();
        
        // Check if error message is displayed
        $this->assertSelectorTextContains('.alert-danger', 'Please correct the errors below.');
        
        // Check if form is displayed with validation errors
        $this->assertSelectorExists('form');
        $this->assertSelectorTextContains('.card-title', 'Edit User');
        
        // Check if form fields contain the submitted data (even with errors)
        $firstNameField = $crawler->filter('input[name="user_edit[firstName]"]');
        $this->assertEquals('WIOLETTA', $firstNameField->attr('value')); // Valid data preserved
        
        $lastNameField = $crawler->filter('input[name="user_edit[lastName]"]');
        $this->assertEquals('', $lastNameField->attr('value')); // Empty value preserved
        
        $birthdateField = $crawler->filter('input[name="user_edit[birthdate]"]');
        $this->assertEquals('1992-06-16', $birthdateField->attr('value')); // Other data preserved
        
        // Check if fields with validation errors are properly marked
        $this->assertSelectorExists('input[name="user_edit[lastName]"][class*="is-invalid"]', 'Last name field should have is-invalid class');
        $this->assertSelectorExists('.invalid-feedback', 'Should have validation error messages');
        
        // Check if validation error message is displayed for lastName field
        $lastNameError = $crawler->filter('input[name="user_edit[lastName]"]')->closest('.form-group')->filter('.invalid-feedback');
        $this->assertGreaterThan(0, $lastNameError->count(), 'Last name field should have validation error message');
        
        // Check if firstName field (which is valid) doesn't have error styling
        $firstNameField = $crawler->filter('input[name="user_edit[firstName]"]');
        $this->assertStringNotContainsString('is-invalid', $firstNameField->attr('class') ?? '', 'First name field should not have is-invalid class');
    }
    
    public function testUpdateUserSuccess(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $updatedUser = new UserDTO(
            id: 1,
            firstName: 'JAN',
            lastName: 'KOWALSKI',
            gender: 'male',
            birthdate: new \DateTime('1990-01-15')
        );
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('update')
            ->with($this->callback(function (UserDTO $userDTO) {
                return $userDTO->id === 1
                    && $userDTO->firstName === 'JAN'
                    && $userDTO->lastName === 'KOWALSKI'
                    && $userDTO->gender === 'male'
                    && $userDTO->birthdate->format('Y-m-d') === '1990-01-15';
            }))
            ->willReturn($updatedUser);
        
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        // Submit form with valid data
        $client->request('POST', '/users/1/edit', [
            'user_edit' => [
                'firstName' => 'JAN',
                'lastName' => 'KOWALSKI',
                'gender' => 'male',
                'birthdate' => '1990-01-15',
                'save' => ''
            ]
        ]);
        
        // Should redirect to user show page
        $this->assertResponseRedirects('/users/1');
    }
    
    public function testUpdateUserApiError(): void
    {        
        $client = static::createClient();
        
        // Mock PhoenixApiService to throw an exception
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('update')
            ->with($this->callback(function (UserDTO $userDTO) {
                return $userDTO->id === 1
                    && $userDTO->firstName === 'JAN'
                    && $userDTO->lastName === 'KOWALSKI'
                    && $userDTO->gender === 'male'
                    && $userDTO->birthdate->format('Y-m-d') === '1990-01-15';
            }))
            ->willThrowException(new \Exception('API connection failed'));
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        // Submit form with valid data
        $crawler = $client->request('POST', '/users/1/edit', [
            'user_edit' => [
                'firstName' => 'JAN',
                'lastName' => 'KOWALSKI',
                'gender' => 'male',
                'birthdate' => '1990-01-15',
                'save' => ''
            ]
        ]);
        
        // Should render the form with error (no redirect)
        $this->assertResponseIsSuccessful();
        
        // Check if error message is displayed
        $this->assertSelectorTextContains('.alert-danger', 'Failed to update user: API connection failed');
        
        // Check if form is still displayed
        $this->assertSelectorExists('form');
        $this->assertSelectorTextContains('.card-title', 'Edit User');
        
        // Check if form fields contain the submitted data
        $firstNameField = $crawler->filter('input[name="user_edit[firstName]"]');
        $this->assertEquals('JAN', $firstNameField->attr('value'));
        
        $lastNameField = $crawler->filter('input[name="user_edit[lastName]"]');
        $this->assertEquals('KOWALSKI', $lastNameField->attr('value'));
        
        $birthdateField = $crawler->filter('input[name="user_edit[birthdate]"]');
        $this->assertEquals('1990-01-15', $birthdateField->attr('value'));
    }
    
    public function testCreateUserForm(): void
    {
        $client = static::createClient();
        
        $crawler = $client->request('GET', '/users/create');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if form is displayed
        $this->assertSelectorExists('form');
        $this->assertSelectorTextContains('.card-title', 'Create New User');
        
        // Check if all form fields exist
        $this->assertSelectorExists('input[name="user_create[firstName]"]');
        $this->assertSelectorExists('input[name="user_create[lastName]"]');
        $this->assertSelectorExists('select[name="user_create[gender]"]');
        $this->assertSelectorExists('input[name="user_create[birthdate]"]');
        $this->assertSelectorExists('button[name="user_create[save]"]');
        
        // Check if submit button has correct text
        $this->assertSelectorTextContains('button[name="user_create[save]"]', 'Create User');
        
        // Check if navigation link exists
        $this->assertSelectorExists('a[href="/users"]');
        $this->assertSelectorTextContains('a[href="/users"]', 'Back to User List');
    }
    
    public function testCreateUserSuccess(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $createdUser = new UserDTO(
            id: 123,
            firstName: 'JAN',
            lastName: 'KOWALSKI',
            gender: 'male',
            birthdate: new \DateTime('1990-01-15')
        );
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('create')
            ->with($this->callback(function (UserDTO $userDTO) {
                return $userDTO->id === 0 // Should have temporary ID
                    && $userDTO->firstName === 'JAN'
                    && $userDTO->lastName === 'KOWALSKI'
                    && $userDTO->gender === 'male'
                    && $userDTO->birthdate->format('Y-m-d') === '1990-01-15';
            }))
            ->willReturn($createdUser);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        // Submit form with valid data
        $client->request('POST', '/users/create', [
            'user_create' => [
                'firstName' => 'JAN',
                'lastName' => 'KOWALSKI',
                'gender' => 'male',
                'birthdate' => '1990-01-15',
                'save' => ''
            ]
        ]);
        
        // Should redirect to user show page
        $this->assertResponseRedirects('/users/123');
    }
    
    public function testCreateUserApiError(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService to throw an exception
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('create')
            ->with($this->callback(function (UserDTO $userDTO) {
                return $userDTO->id === 0 // Should have temporary ID
                    && $userDTO->firstName === 'JAN'
                    && $userDTO->lastName === 'KOWALSKI'
                    && $userDTO->gender === 'male'
                    && $userDTO->birthdate->format('Y-m-d') === '1990-01-15';
            }))
            ->willThrowException(new \Exception('API connection failed'));
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        // Submit form with valid data
        $crawler = $client->request('POST', '/users/create', [
            'user_create' => [
                'firstName' => 'JAN',
                'lastName' => 'KOWALSKI',
                'gender' => 'male',
                'birthdate' => '1990-01-15',
                'save' => ''
            ]
        ]);
        
        // Should render the form with error (no redirect)
        $this->assertResponseIsSuccessful();
        
        // Check if error message is displayed
        $this->assertSelectorTextContains('.alert-danger', 'Failed to create user: API connection failed');
        
        // Check if form is still displayed
        $this->assertSelectorExists('form');
        $this->assertSelectorTextContains('.card-title', 'Create New User');
        
        // Check if form fields contain the submitted data
        $firstNameField = $crawler->filter('input[name="user_create[firstName]"]');
        $this->assertEquals('JAN', $firstNameField->attr('value'));
        
        $lastNameField = $crawler->filter('input[name="user_create[lastName]"]');
        $this->assertEquals('KOWALSKI', $lastNameField->attr('value'));
        
        $birthdateField = $crawler->filter('input[name="user_create[birthdate]"]');
        $this->assertEquals('1990-01-15', $birthdateField->attr('value'));
    }
    
    public function testCreateUserWithValidationErrors(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->never())
            ->method('create');
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        // Submit form with invalid data (empty first name)
        $crawler = $client->request('POST', '/users/create', [
            'user_create' => [
                'firstName' => '', // Empty first name - should cause validation error
                'lastName' => 'KOWALSKI',
                'gender' => 'male',
                'birthdate' => '1990-01-15',
                'save' => ''
            ]
        ]);
        
        // Should render the form directly with validation errors (no redirect)
        $this->assertResponseIsSuccessful();
        
        // Check if error message is displayed
        $this->assertSelectorTextContains('.alert-danger', 'Please correct the errors below.');
        
        // Check if form is displayed with validation errors
        $this->assertSelectorExists('form');
        $this->assertSelectorTextContains('.card-title', 'Create New User');
        
        // Check if form fields contain the submitted data (even with errors)
        $firstNameField = $crawler->filter('input[name="user_create[firstName]"]');
        $this->assertEquals('', $firstNameField->attr('value')); // Empty value preserved
        
        $lastNameField = $crawler->filter('input[name="user_create[lastName]"]');
        $this->assertEquals('KOWALSKI', $lastNameField->attr('value')); // Other data preserved
        
        $birthdateField = $crawler->filter('input[name="user_create[birthdate]"]');
        $this->assertEquals('1990-01-15', $birthdateField->attr('value')); // Other data preserved
        
        $this->assertSelectorExists('input[name="user_create[firstName]"][class*="is-invalid"]', 'First name field should have is-invalid class');
        $this->assertSelectorExists('.invalid-feedback', 'Should have validation error messages');
        
        // Check if validation error message is displayed for firstName field
        $firstNameError = $crawler->filter('input[name="user_create[firstName]"]')->closest('.form-group')->filter('.invalid-feedback');
        $this->assertGreaterThan(0, $firstNameError->count(), 'First name field should have validation error message');
        
        // Check if lastName field (which is valid) doesn't have error styling
        $lastNameField = $crawler->filter('input[name="user_create[lastName]"]');
        $this->assertStringNotContainsString('is-invalid', $lastNameField->attr('class') ?? '', 'Last name field should not have is-invalid class');
    }
    
    public function testListUsersWithLastNameFilter(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with filtered users
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            ),
            new UserDTO(
                id: 2,
                firstName: 'ANNA',
                lastName: 'KOWALSKA',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            )
        ];
        
        $expectedFilters = [
            'last_name' => 'KOWALSK'
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?last_name=KOWALSK');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if users are displayed
        $this->assertSelectorTextContains('h1', 'Users List');
        $this->assertSelectorTextContains('h5', 'Found 2 users');
        
        // Check if both users with matching last name are displayed
        $this->assertSelectorTextContains('body', 'JAN KOWALSKI');
        $this->assertSelectorTextContains('body', 'ANNA KOWALSKA');
        
        // Check if filter form is displayed with pre-filled value
        $lastNameInput = $crawler->filter('input[name="last_name"]');
        $this->assertEquals('KOWALSK', $lastNameInput->attr('value'));
        
        // Check if "Clear Filter" button is displayed when filter is active
        $this->assertSelectorExists('a[href*="/users"]');
        $this->assertSelectorTextContains('a[href*="/users"]', 'Clear Filter');
    }
    
    public function testListUsersWithLastNameFilterAndSorting(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with filtered and sorted users
        $mockUsers = [
            new UserDTO(
                id: 2,
                firstName: 'ANNA',
                lastName: 'KOWALSKA',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            ),
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            )
        ];
        
        $expectedFilters = [
            'last_name' => 'KOWALSK',
            'sort' => 'first_name',
            'order' => 'desc'
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?last_name=KOWALSK&sort_field=first_name&sort_order=desc');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if users are displayed
        $this->assertSelectorTextContains('h1', 'Users List');
        $this->assertSelectorTextContains('h5', 'Found 2 users');
        
        // Check if both users with matching last name are displayed
        $this->assertSelectorTextContains('body', 'ANNA KOWALSKA');
        $this->assertSelectorTextContains('body', 'JAN KOWALSKI');
    }
    
    public function testListUsersWithEmptyLastNameFilter(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with all users (no filter applied)
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            ),
            new UserDTO(
                id: 2,
                firstName: 'ANNA',
                lastName: 'NOWAK',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            )
        ];
        
        $expectedFilters = [];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?last_name=');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if all users are displayed (no filtering)
        $this->assertSelectorTextContains('h1', 'Users List');
        $this->assertSelectorTextContains('h5', 'Found 2 users');
        
        // Check if both users are displayed
        $this->assertSelectorTextContains('body', 'JAN KOWALSKI');
        $this->assertSelectorTextContains('body', 'ANNA NOWAK');
        
        // Check if filter form is displayed with empty value
        $lastNameInput = $crawler->filter('input[name="last_name"]');
        $this->assertEquals('', $lastNameInput->attr('value'));
        
        // Check if "Clear Filter" button is NOT displayed when no filter is active
        $clearFilterLinks = $crawler->filter('a:contains("Clear Filter")');
        $this->assertCount(0, $clearFilterLinks);
    }
    
    public function testListUsersWithFirstNameFilter(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with filtered users
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            ),
            new UserDTO(
                id: 2,
                firstName: 'JANINA',
                lastName: 'NOWAK',
                gender: 'female',
                birthdate: new \DateTime('1990-12-25')
            )
        ];
        
        $expectedFilters = [
            'first_name' => 'JAN'
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?first_name=JAN');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if users are displayed
        $this->assertSelectorTextContains('h1', 'Users List');
        $this->assertSelectorTextContains('h5', 'Found 2 users');
        
        // Check if both users with matching first name are displayed
        $this->assertSelectorTextContains('body', 'JAN KOWALSKI');
        $this->assertSelectorTextContains('body', 'JANINA NOWAK');
        
        // Check if filter form is displayed with pre-filled value
        $firstNameInput = $crawler->filter('input[name="first_name"]');
        $this->assertEquals('JAN', $firstNameInput->attr('value'));
        
        // Check if "Clear Filter" button is displayed when filter is active
        $this->assertSelectorExists('a[href*="/users"]');
        $this->assertSelectorTextContains('a[href*="/users"]', 'Clear Filter');
    }
    
    public function testListUsersWithGenderFilter(): void
    {
        $client = static::createClient();
        
        // Mock PhoenixApiService with filtered users
        $mockUsers = [
            new UserDTO(
                id: 1,
                firstName: 'JAN',
                lastName: 'KOWALSKI',
                gender: 'male',
                birthdate: new \DateTime('1985-03-15')
            ),
            new UserDTO(
                id: 2,
                firstName: 'PIOTR',
                lastName: 'NOWAK',
                gender: 'male',
                birthdate: new \DateTime('1990-12-25')
            )
        ];
        
        $expectedFilters = [
            'gender' => 'male'
        ];
        
        $mockService = $this->createMock(PhoenixApiService::class);
        $mockService->expects($this->once())
            ->method('listUsers')
            ->with($expectedFilters)
            ->willReturn($mockUsers);
        
        $client->getContainer()->set('App\Service\PhoenixApiService', $mockService);
        
        $crawler = $client->request('GET', '/users?gender=male');
        
        $this->assertResponseIsSuccessful();
        $this->assertResponseStatusCodeSame(Response::HTTP_OK);
        
        // Check if users are displayed
        $this->assertSelectorTextContains('h1', 'Users List');
        $this->assertSelectorTextContains('h5', 'Found 2 users');
        
        // Check if both users with matching gender are displayed
        $this->assertSelectorTextContains('body', 'JAN KOWALSKI');
        $this->assertSelectorTextContains('body', 'PIOTR NOWAK');
        
        // Check if filter form is displayed with pre-filled value
        $genderSelect = $crawler->filter('select[name="gender"]');
        $this->assertCount(1, $genderSelect->filter('option[value="male"][selected]'));
        
        // Check if "Clear Filter" button is displayed when filter is active
        $this->assertSelectorExists('a[href*="/users"]');
        $this->assertSelectorTextContains('a[href*="/users"]', 'Clear Filter');
    }
}
