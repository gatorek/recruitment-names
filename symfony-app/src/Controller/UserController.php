<?php

namespace App\Controller;

use App\Exception\InvalidUserIdException;
use App\Service\PhoenixApiService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
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

}
