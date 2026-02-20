import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../../domain/entities/warranty_entity.dart';

class WarrantyRegistrationPage extends StatefulWidget {
  const WarrantyRegistrationPage({super.key});

  @override
  State<WarrantyRegistrationPage> createState() => _WarrantyRegistrationPageState();
}

class _WarrantyRegistrationPageState extends State<WarrantyRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _serialNumberController = TextEditingController();
  List<ProductEntity> _products = [];
  ProductEntity? _selectedProduct;

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(GetProductsEvent());
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a product'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      context.read<CustomerBloc>().add(
            RegisterWarrantyEvent(
              productId: _selectedProduct!.id,
              serialNumber: _serialNumberController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Register Warranty'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is ProductsLoaded) {
            setState(() {
              _products = state.products;
            });
          } else if (state is WarrantyRegistered) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Warranty registered successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is CustomerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is CustomerLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Register Your Product',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Activate warranty protection',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonFormField<ProductEntity>(
                      value: _selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'Select Product',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: _products.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${product.category} • ${product.warrantyMonths} months warranty',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _selectedProduct = value;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a product';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _serialNumberController,
                    label: 'Serial Number',
                    hint: 'Enter product serial number',
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter serial number';
                      }
                      return null;
                    },
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'The serial number can be found on the product label or packaging',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Register Warranty',
                    onPressed: isLoading ? null : _handleSubmit,
                    isLoading: isLoading,
                    icon: Icons.verified_user,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
