import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/sales_personnel_entities.dart';
import '../bloc/sales_personnel_bloc.dart';
import '../bloc/sales_personnel_event.dart';
import '../bloc/sales_personnel_state.dart';

class SalesLeadsPage extends StatefulWidget {
  const SalesLeadsPage({super.key});

  @override
  State<SalesLeadsPage> createState() => _SalesLeadsPageState();
}

class _SalesLeadsPageState extends State<SalesLeadsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SalesPersonnelBloc>().add(const LoadLeadsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Leads', style: TextStyle(fontWeight: FontWeight.w700)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Add Lead', icon: Icon(Icons.person_add_rounded, size: 20)),
            Tab(text: 'All Leads', icon: Icon(Icons.list_alt_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AddLeadForm(
            onSuccess: () {
              _tabController.animateTo(1);
              context.read<SalesPersonnelBloc>().add(const LoadLeadsEvent());
            },
          ),
          _LeadsList(),
        ],
      ),
    );
  }
}

class _AddLeadForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddLeadForm({required this.onSuccess});

  @override
  State<_AddLeadForm> createState() => _AddLeadFormState();
}

class _AddLeadFormState extends State<_AddLeadForm> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _leadType = 'HOT';
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for GPS location...'), backgroundColor: Colors.orange),
      );
      return;
    }

    context.read<SalesPersonnelBloc>().add(
      CreateLeadEvent(
        customerName: _customerNameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        leadType: _leadType,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalesPersonnelBloc, SalesPersonnelState>(
      listener: (context, state) {
        if (state is LeadCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lead created successfully!'), backgroundColor: Color(0xFF2563EB)),
          );
          _customerNameController.clear();
          _businessNameController.clear();
          _phoneController.clear();
          _addressController.clear();
          _notesController.clear();
          widget.onSuccess();
        } else if (state is SalesPersonnelError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _latitude != null ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _latitude != null ? const Color(0xFF2563EB) : const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _latitude != null ? Icons.check_circle : Icons.gps_fixed,
                      color: _latitude != null ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _latitude != null ? 'GPS Location Captured' : 'Getting location...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _latitude != null ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
                      ),
                    ),
                    if (_isLoadingLocation) ...[
                      const Spacer(),
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Lead Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: ['HOT', 'WARM', 'COLD'].map((type) {
                  final isSelected = _leadType == type;
                  final color = type == 'HOT'
                      ? Colors.red
                      : type == 'WARM'
                          ? Colors.orange
                          : Colors.blue;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: type != 'COLD' ? 8 : 0),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _leadType = type),
                        selectedColor: color.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? color : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: Colors.grey[100],
                        side: BorderSide(color: isSelected ? color : Colors.grey[300]!),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _buildField(_customerNameController, 'Customer Name', Icons.person,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _buildField(_businessNameController, 'Business Name', Icons.business,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _buildField(_phoneController, 'Phone Number', Icons.phone,
                  keyboard: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _buildField(_addressController, 'Address (Optional)', Icons.location_on_outlined),
              const SizedBox(height: 12),
              _buildField(_notesController, 'Notes (Optional)', Icons.notes, maxLines: 3),
              const SizedBox(height: 24),
              BlocBuilder<SalesPersonnelBloc, SalesPersonnelState>(
                builder: (context, state) {
                  final isLoading = state is SalesPersonnelLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.person_add_rounded),
                      label: Text(isLoading ? 'Creating...' : 'Create Lead'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _LeadsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesPersonnelBloc, SalesPersonnelState>(
      builder: (context, state) {
        if (state is SalesPersonnelLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
        }
        if (state is LeadsLoaded) {
          if (state.leads.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No leads yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Add your first sales lead', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<SalesPersonnelBloc>().add(const LoadLeadsEvent());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.leads.length,
              itemBuilder: (context, index) => _buildLeadCard(state.leads[index]),
            ),
          );
        }
        return Center(
          child: ElevatedButton(
            onPressed: () => context.read<SalesPersonnelBloc>().add(const LoadLeadsEvent()),
            child: const Text('Load Leads'),
          ),
        );
      },
    );
  }

  Widget _buildLeadCard(SalesLead lead) {
    final leadType = lead.leadType ?? 'UNKNOWN';
    final color = leadType == 'HOT'
        ? Colors.red
        : leadType == 'WARM'
            ? Colors.orange
            : Colors.blue;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(lead.customerName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(leadType,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.business, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Expanded(child: Text(lead.businessName, style: TextStyle(color: Colors.grey[700]))),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.phone, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(lead.phoneNumber, style: TextStyle(color: Colors.grey[700])),
          ]),
          if (lead.notes != null && lead.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.notes, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(lead.notes!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(lead.status,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text(
                '${lead.createdAt.day}/${lead.createdAt.month}/${lead.createdAt.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
