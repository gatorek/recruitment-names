<?php

namespace App\Form;

use App\DTO\UserDTO;
use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;
use Symfony\Component\Form\Extension\Core\Type\DateType;
use Symfony\Component\Form\Extension\Core\Type\SubmitType;
use Symfony\Component\Form\Extension\Core\Type\TextType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolver;
use Symfony\Component\Validator\Constraints\NotBlank;
use Symfony\Component\Validator\Constraints\Length;

class UserCreateType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options = []): void
    {
        $builder
                ->add('firstName', TextType::class, [
                    'label' => 'First Name',
                    'mapped' => false,
                    'constraints' => [
                        new NotBlank(['message' => 'First name cannot be blank']),
                        new Length(['min' => 1, 'max' => 100])
                    ],
                    'attr' => [
                        'class' => 'form-control',
                        'placeholder' => 'Enter first name'
                    ]
                ])
            ->add('lastName', TextType::class, [
                'label' => 'Last Name',
                'mapped' => false,
                'constraints' => [
                    new NotBlank(['message' => 'Last name cannot be blank']),
                    new Length(['min' => 1, 'max' => 100])
                ],
                'attr' => [
                    'class' => 'form-control',
                    'placeholder' => 'Enter last name'
                ]
            ])
            ->add('gender', ChoiceType::class, [
                'label' => 'Gender',
                'mapped' => false,
                'choices' => [
                    'Male' => 'male',
                    'Female' => 'female'
                ],
                'attr' => [
                    'class' => 'form-select'
                ]
            ])
            ->add('birthdate', DateType::class, [
                'label' => 'Birth Date',
                'mapped' => false,
                'widget' => 'single_text',
                'constraints' => [
                    new NotBlank(['message' => 'Birth date cannot be blank'])
                ],
                'attr' => [
                    'class' => 'form-control'
                ]
            ])
            ->add('save', SubmitType::class, [
                'label' => 'Create User',
                'attr' => [
                    'class' => 'btn btn-primary'
                ]
            ]);
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => null,
        ]);
    }
}
